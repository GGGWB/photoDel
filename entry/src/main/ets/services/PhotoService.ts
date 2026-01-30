/**
 * PhotoService.ts
 * 
 * 照片管理服务 (Photo Management Service)
 * 负责与系统媒体库 (MediaLibraryKit) 交互。
 * 
 * 核心功能：
 * - 获取相册资源 (getRandomAssets)。
 * - 移动照片到回收站 (moveToTrash)。
 * - 统计相册总数 (getAlbumCount)。
 * 
 * v2.4 修复：
 * - 显式查询 WIDTH 和 HEIGHT 列，解决全屏预览时的 Crash 问题。
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates, preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class PhotoService {
    private context: common.UIAbilityContext;
    private phHelper: photoAccessHelper.PhotoAccessHelper;

    // Static Session Deck
    private static sessionAssets: Array<photoAccessHelper.PhotoAsset> = [];
    private static sessionCursor: number = 0;
    private static isInitialized: boolean = false;

    // Persistent History
    private static seenUris: Set<string> = new Set();
    private static preferences: preferences.Preferences | null = null;
    private static readonly PREF_NAME = 'photo_cleaner_history';
    private static readonly KEY_SEEN_URIS = 'seen_uris';

    constructor(context: common.UIAbilityContext) {
        this.context = context;
        this.phHelper = photoAccessHelper.getPhotoAccessHelper(context);
    }

    /**
     * Initialize Preferences and load seen URIs
     */
    private static async initPreferences(context: common.UIAbilityContext): Promise<void> {
        if (PhotoService.preferences) return;
        try {
            PhotoService.preferences = await preferences.getPreferences(context, PhotoService.PREF_NAME);
            const seenStr = await PhotoService.preferences.get(PhotoService.KEY_SEEN_URIS, '[]') as string;
            const seenArray = JSON.parse(seenStr) as string[];
            PhotoService.seenUris = new Set(seenArray);
            console.info(`PhotoService: Loaded ${PhotoService.seenUris.size} seen photos from history.`);
        } catch (err) {
            console.error('PhotoService: Failed to init preferences', JSON.stringify(err));
        }
    }

    /**
     * Mark a photo as seen (kept) and persist it
     */
    public static async markAsSeen(context: common.UIAbilityContext, uri: string): Promise<void> {
        if (!uri) return;
        if (PhotoService.seenUris.has(uri)) return;

        PhotoService.seenUris.add(uri);

        // Persist
        if (PhotoService.preferences) {
            try {
                const seenArray = Array.from(PhotoService.seenUris);
                await PhotoService.preferences.put(PhotoService.KEY_SEEN_URIS, JSON.stringify(seenArray));
                await PhotoService.preferences.flush();
            } catch (err) {
                console.error('PhotoService: Failed to save history', JSON.stringify(err));
            }
        }
    }

    /**
     * Preload: Initialize the session deck in background
     */
    public static async preload(context: common.UIAbilityContext): Promise<void> {
        if (PhotoService.isInitialized) {
            console.info('PhotoService: Session already initialized.');
            return;
        }
        await PhotoService.loadSession(context);
    }

    /**
     * Consume preloaded assets - Now just returns the first batch from the deck
     */
    public static consumePreloadedAssets(): Array<photoAccessHelper.PhotoAsset> | null {
        if (PhotoService.isInitialized && PhotoService.sessionAssets.length > 0) {
            // Check if cursor is at 0 (fresh start)
            if (PhotoService.sessionCursor === 0) {
                return PhotoService.getNextBatch(20);
            }
        }
        return null;
    }

    /**
     * Load all assets and shuffle them into the session deck
     */
    public static async loadSession(context: common.UIAbilityContext): Promise<void> {
        try {
            console.info('PhotoService: Loading session deck...');

            // 1. Init Preferences
            await PhotoService.initPreferences(context);

            const phHelper = photoAccessHelper.getPhotoAccessHelper(context);
            let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();

            // Fetch ALL assets (no limit)
            let fetchOptions: photoAccessHelper.FetchOptions = {
                fetchColumns: [
                    photoAccessHelper.PhotoKeys.DISPLAY_NAME,
                    photoAccessHelper.PhotoKeys.DATE_ADDED,
                    photoAccessHelper.PhotoKeys.URI,
                    photoAccessHelper.PhotoKeys.WIDTH,
                    photoAccessHelper.PhotoKeys.HEIGHT
                ],
                predicates: predicates
            };

            const fetchResult = await phHelper.getAssets(fetchOptions);
            if (fetchResult === undefined) {
                console.error('PhotoService: getAssets failed');
                return;
            }

            const totalCount = fetchResult.getCount();
            if (totalCount === 0) {
                fetchResult.close();
                PhotoService.sessionAssets = [];
                PhotoService.isInitialized = true;
                return;
            }

            // Get all objects
            const allAssets = await fetchResult.getAllObjects();
            fetchResult.close();

            // 2. Filter out SEEN assets
            const freshAssets = allAssets.filter(asset => !PhotoService.seenUris.has(asset.uri));
            console.info(`PhotoService: Filtered ${allAssets.length - freshAssets.length} seen photos. Remaining: ${freshAssets.length}`);

            // 3. Fisher-Yates Shuffle
            for (let i = freshAssets.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [freshAssets[i], freshAssets[j]] = [freshAssets[j], freshAssets[i]];
            }

            PhotoService.sessionAssets = freshAssets;
            PhotoService.sessionCursor = 0;
            PhotoService.isInitialized = true;
            console.info(`PhotoService: Session loaded with ${freshAssets.length} assets.`);

        } catch (err) {
            console.error(`PhotoService: loadSession failed: ${JSON.stringify(err)}`);
        }
    }

    /**
     * Get next batch from the deck
     */
    public static getNextBatch(count: number = 20): Array<photoAccessHelper.PhotoAsset> {
        if (!PhotoService.isInitialized) {
            console.warn('PhotoService: Session not initialized, returning empty.');
            return [];
        }

        const start = PhotoService.sessionCursor;
        const end = Math.min(start + count, PhotoService.sessionAssets.length);

        if (start >= PhotoService.sessionAssets.length) {
            console.info('PhotoService: Session exhausted.');
            return [];
        }

        const batch = PhotoService.sessionAssets.slice(start, end);
        PhotoService.sessionCursor = end;
        console.info(`PhotoService: Dealt batch ${start}-${end} (Total: ${PhotoService.sessionAssets.length})`);

        return batch;
    }

    /**
     * Legacy instance method - redirected to static
     */
    async getRandomAssets(count: number = 20): Promise<Array<photoAccessHelper.PhotoAsset>> {
        if (!PhotoService.isInitialized) {
            await PhotoService.loadSession(this.context);
        }
        return PhotoService.getNextBatch(count);
    }

    /**
     * Move asset to trash using deleteAssets static method
     */
    private pendingTrash: Array<photoAccessHelper.PhotoAsset> = [];

    /**
     * Mark asset for deletion (queue it)
     */
    async moveToTrash(asset: photoAccessHelper.PhotoAsset): Promise<void> {
        this.pendingTrash.push(asset);
        // Optimistic return, no actual deletion yet
    }

    /**
     * Commit all pending deletions
     * Triggers the system permission dialog once for all photos
     */
    async commitDeletions(): Promise<void> {
        if (this.pendingTrash.length === 0) return;

        try {
            await photoAccessHelper.MediaAssetChangeRequest.deleteAssets(this.context, this.pendingTrash);
            this.pendingTrash = []; // Clear queue on success
        } catch (err) {
            console.error(`PhotoService: commitDeletions failed: ${JSON.stringify(err)}`);
            // Queue remains if failed, so we don't lose them? 
            // Better to clear or handle retry. For MVP, we clear to avoid repeating error loops.
            this.pendingTrash = [];
        }
    }

    /**
     * Get total photo count in album
     */
    async getAlbumCount(): Promise<number> {
        try {
            let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
            let fetchOptions: photoAccessHelper.FetchOptions = {
                fetchColumns: [],
                predicates: predicates
            };
            const fetchResult = await this.phHelper.getAssets(fetchOptions);
            if (fetchResult === undefined) {
                return 0;
            }
            const count = fetchResult.getCount();
            fetchResult.close();
            return count;
        } catch (err) {
            console.error(`PhotoService: getAlbumCount failed: ${JSON.stringify(err)}`);
            return 0;
        }
    }

    /**
     * Get assets from trash - simplified version
     * Note: System trash access may require elevated permissions
     * For now, return empty and guide user to system Photos app
     */
    /**
     * Get assets from System Trash
     */
    // Trash features removed as per user request (v2.7)

}

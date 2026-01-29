import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class PhotoService {
    private context: common.UIAbilityContext;
    private phHelper: photoAccessHelper.PhotoAccessHelper;

    constructor(context: common.UIAbilityContext) {
        this.context = context;
        this.phHelper = photoAccessHelper.getPhotoAccessHelper(context);
    }

    /**
     * Randomly retrieve a batch of photos.
     */
    async getRandomAssets(count: number = 20): Promise<Array<photoAccessHelper.PhotoAsset>> {
        try {
            let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
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

            const fetchResult = await this.phHelper.getAssets(fetchOptions);
            if (fetchResult === undefined) {
                console.error('PhotoService: getAssets failed');
                return [];
            }

            const totalCount = fetchResult.getCount();
            if (totalCount === 0) {
                fetchResult.close();
                return [];
            }

            // Generate random unique indices
            const indices = new Set<number>();
            const safeCount = Math.min(count, totalCount);
            while (indices.size < safeCount) {
                const randomIndex = Math.floor(Math.random() * totalCount);
                indices.add(randomIndex);
            }

            const allAssets = await fetchResult.getAllObjects();
            fetchResult.close();

            const selectedAssets: Array<photoAccessHelper.PhotoAsset> = [];
            indices.forEach((index: number): void => {
                if (allAssets[index]) {
                    selectedAssets.push(allAssets[index]);
                }
            });

            return selectedAssets;
        } catch (err) {
            console.error(`PhotoService: getRandomAssets failed: ${JSON.stringify(err)}`);
            return [];
        }
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
    async getTrashAssets(): Promise<Array<photoAccessHelper.PhotoAsset>> {
        // Accessing system trash requires special permissions
        // Return empty array - user should check system Photos app
        console.info('PhotoService: Trash access requires system Photos app');
        return [];
    }

    /**
     * Recover asset - Guide user to system album
     */
    async recoverAsset(asset: photoAccessHelper.PhotoAsset): Promise<void> {
        // Recovery from trash requires system UI
        console.info('PhotoService: Please recover from system Photos app');
    }
}

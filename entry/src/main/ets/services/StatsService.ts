import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREFERENCES_NAME = 'photo_cleaner_stats';
const KEY_TOTAL_PROCESSED = 'totalProcessed';
const KEY_TOTAL_KEPT = 'totalKept';
const KEY_TOTAL_DELETED = 'totalDeleted';

/**
 * 统计数据持久化服务
 */
export class StatsService {
    private context: common.UIAbilityContext;
    private dataPreferences: preferences.Preferences | null = null;

    constructor(context: common.UIAbilityContext) {
        this.context = context;
    }

    async init(): Promise<void> {
        try {
            this.dataPreferences = await preferences.getPreferences(this.context, PREFERENCES_NAME);
        } catch (err) {
            console.error('StatsService init failed:', JSON.stringify(err));
        }
    }

    async getTotalProcessed(): Promise<number> {
        // 已处理数 = 保留数 + 删除数 (确保数据绝对一致)
        let kept = await this.getTotalKept();
        let deleted = await this.getTotalDeleted();
        return kept + deleted;
    }

    async getTotalKept(): Promise<number> {
        if (!this.dataPreferences) return 0;
        try {
            return await this.dataPreferences.get(KEY_TOTAL_KEPT, 0) as number;
        } catch (err) {
            return 0;
        }
    }

    async getTotalDeleted(): Promise<number> {
        if (!this.dataPreferences) return 0;
        try {
            return await this.dataPreferences.get(KEY_TOTAL_DELETED, 0) as number;
        } catch (err) {
            return 0;
        }
    }

    async incrementKept(): Promise<void> {
        if (!this.dataPreferences) return;
        try {
            let current = await this.getTotalKept();
            await this.dataPreferences.put(KEY_TOTAL_KEPT, current + 1);
            await this.dataPreferences.flush();
        } catch (err) {
            console.error('incrementKept failed:', JSON.stringify(err));
        }
    }

    async incrementDeleted(): Promise<void> {
        if (!this.dataPreferences) return;
        try {
            let current = await this.getTotalDeleted();
            await this.dataPreferences.put(KEY_TOTAL_DELETED, current + 1);
            await this.dataPreferences.flush();
        } catch (err) {
            console.error('incrementDeleted failed:', JSON.stringify(err));
        }
    }

    async addProcessed(count: number): Promise<void> {
        if (!this.dataPreferences) return;
        try {
            let current = await this.getTotalProcessed();
            await this.dataPreferences.put(KEY_TOTAL_PROCESSED, current + count);
            await this.dataPreferences.flush();
        } catch (err) {
            console.error('addProcessed failed:', JSON.stringify(err));
        }
    }

    async resetDeleted(): Promise<void> {
        if (!this.dataPreferences) return;
        await this.dataPreferences.put(KEY_TOTAL_DELETED, 0);
        await this.dataPreferences.flush();
    }

    async resetKept(): Promise<void> {
        if (!this.dataPreferences) return;
        await this.dataPreferences.put(KEY_TOTAL_KEPT, 0);
        await this.dataPreferences.flush();
    }
}

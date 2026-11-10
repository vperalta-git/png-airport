import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { OfflineSyncService, SyncEventPayload, SyncBatchResult } from './offline-sync.service';

@ApiTags('Offline Sync Engine')
@Controller('sync')
export class OfflineSyncController {
  constructor(private readonly syncService: OfflineSyncService) {}

  @Post('events')
  @ApiOperation({ summary: 'Submit batched offline events from Driver or Security Mobile App with idempotency deduplication' })
  @ApiResponse({ status: 200, description: 'Events processed and synced.' })
  async syncEvents(@Body() events: SyncEventPayload[]): Promise<SyncBatchResult> {
    return this.syncService.processSyncBatch(events);
  }
}


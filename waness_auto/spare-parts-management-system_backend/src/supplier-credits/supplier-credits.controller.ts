import { Controller, Get, Post, Body, Param, Delete, Put, UseGuards, Req, Query } from '@nestjs/common';
import { SupplierCreditsService } from './supplier-credits.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { CreditStatus } from './supplier-credit.entity';

@Controller('supplier-credits')
@UseGuards(JwtAuthGuard)
export class SupplierCreditsController {
  constructor(private readonly supplierCreditsService: SupplierCreditsService) {}

  @Post('manual')
  createManualCredit(
    @Body() body: { supplier_id: string; amount: number; notes?: string; expiry_date?: string },
    @Req() req
  ) {
    const userId = req.user.sub;
    const expiryDate = body.expiry_date ? new Date(body.expiry_date) : undefined;
    return this.supplierCreditsService.createManualCredit(
      body.supplier_id,
      body.amount,
      body.notes,
      expiryDate
    );
  }

  @Post('apply/:purchaseId')
  applyCreditsToPurchase(
    @Param('purchaseId') purchaseId: string,
    @Body() body: { supplier_id: string; amount: number }
  ) {
    return this.supplierCreditsService.applyCreditsToPurchase(
      purchaseId,
      body.supplier_id,
      body.amount
    );
  }

  @Post('auto-apply/:purchaseId')
  autoApplyCreditsToPurchase(@Param('purchaseId') purchaseId: string) {
    return this.supplierCreditsService.autoApplyCreditsToPurchase(purchaseId);
  }

  @Get()
  findAll(@Query('supplier_id') supplierId?: string, @Query('status') status?: CreditStatus) {
    if (supplierId) {
      return this.supplierCreditsService.findBySupplier(supplierId);
    }
    return this.supplierCreditsService.findAll();
  }

  @Get('available/:supplierId')
  getAvailableCredits(@Param('supplierId') supplierId: string) {
    return this.supplierCreditsService.getAvailableCredits(supplierId);
  }

  @Get('total-available/:supplierId')
  getTotalAvailableCredit(@Param('supplierId') supplierId: string) {
    return this.supplierCreditsService.getTotalAvailableCredit(supplierId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.supplierCreditsService.findOne(id);
  }

  @Get(':id/usage-history')
  getCreditUsageHistory(@Param('id') id: string) {
    return this.supplierCreditsService.getCreditUsageHistory(id);
  }

  @Put(':id/status')
  updateStatus(@Param('id') id: string, @Body() body: { status: CreditStatus }) {
    return this.supplierCreditsService.updateCreditStatus(id, body.status);
  }

  @Post('check-expired')
  checkAndUpdateExpiredCredits() {
    return this.supplierCreditsService.checkAndUpdateExpiredCredits();
  }
} 


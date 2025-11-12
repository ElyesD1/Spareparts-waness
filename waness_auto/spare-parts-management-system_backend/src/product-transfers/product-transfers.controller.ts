import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { ProductTransfersService } from './product-transfers.service';
import { CreateProductTransferDto } from './dto/create-product-transfer.dto';
import { UpdateProductTransferDto, ApproveTransferDto, RejectTransferDto, ProcessTransferDto } from './dto/update-product-transfer.dto';

@Controller('product-transfers')
export class ProductTransfersController {
  constructor(private readonly productTransfersService: ProductTransfersService) {}

  @Post()
  create(@Body() createProductTransferDto: CreateProductTransferDto, @Request() req?: any) {
    // In a real app, you would get user info from authentication
    // For now, we'll use the provided user ID or extract from request
    return this.productTransfersService.create(createProductTransferDto);
  }

  @Get()
  findAll(@Query('warehouse_id') warehouseId?: string) {
    if (warehouseId) {
      return this.productTransfersService.findByWarehouse(warehouseId);
    }
    
    return this.productTransfersService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.productTransfersService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateProductTransferDto: UpdateProductTransferDto) {
    return this.productTransfersService.update(id, updateProductTransferDto);
  }

  @Post(':id/approve')
  approve(@Param('id') id: string, @Body() approveDto: ApproveTransferDto) {
    return this.productTransfersService.approve(id, approveDto);
  }

  @Post(':id/reject')
  reject(@Param('id') id: string, @Body() rejectDto: RejectTransferDto) {
    return this.productTransfersService.reject(id, rejectDto);
  }

  @Post(':id/process')
  process(@Param('id') id: string, @Body() processDto: ProcessTransferDto) {
    return this.productTransfersService.process(id, processDto);
  }

  @Post(':id/complete')
  complete(@Param('id') id: string) {
    return this.productTransfersService.complete(id);
  }

  @Post(':id/cancel')
  cancel(@Param('id') id: string, @Body('user_id') userId: string) {
    if (!userId) {
      throw new BadRequestException('User ID is required for cancellation');
    }
    return this.productTransfersService.cancel(id, userId);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.productTransfersService.remove(id);
  }
}


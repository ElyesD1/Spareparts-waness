import { Controller, Get, Post, Body, Param, UseGuards, Req, Put, Delete, ValidationPipe, Patch } from '@nestjs/common';
import { CreditSalesService } from './credit-sales.service';
import { CreateCreditSaleDto } from './dto/create-credit-sale.dto';
import { CreateCreditSaleItemDto } from '../credit-sale-items/dto/create-credit-sale-item.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('credit-sales')
@UseGuards(JwtAuthGuard)
export class CreditSalesController {
  constructor(private readonly creditSalesService: CreditSalesService) {}

  @Post()
  create(@Body(ValidationPipe) createCreditSaleDto: CreateCreditSaleDto, @Req() req) {
    const userId = req.user.sub;
    
    // Comprehensive debug logging
    console.log('=== CREDIT SALE CREATION REQUEST ===');
    console.log('Raw DTO:', createCreditSaleDto);
    console.log('DTO keys:', Object.keys(createCreditSaleDto));
    console.log('Items type:', typeof createCreditSaleDto.items);
    console.log('Items value:', createCreditSaleDto.items);
    console.log('Full request body:', req.body);
    console.log('Request body keys:', Object.keys(req.body));
    console.log('Content-Type:', req.headers['content-type']);
    console.log('Products field value:', req.body.products);
    console.log('Products field type:', typeof req.body.products);
    
    // Check if items might be in a different field name
    const possibleItemFields = ['items', 'Items', 'ITEMS', 'credit_sale_items', 'creditSaleItems', 'products', 'Products'];
    let itemsFound: CreateCreditSaleItemDto[] | null = null;
    
    for (const field of possibleItemFields) {
      if (req.body[field] && Array.isArray(req.body[field])) {
        itemsFound = req.body[field];
        console.log(`Found items in field: ${field}`);
        break;
      }
    }
    
    // Validate items field
    if (!createCreditSaleDto.items && !itemsFound) {
      console.error('No items field found in any format');
      console.error('Available fields in request body:', Object.keys(req.body));
      throw new Error('Items field is required');
    }
    
    // Use items from alternative source if main items field is empty
    if (!createCreditSaleDto.items && itemsFound) {
      createCreditSaleDto.items = itemsFound;
      console.log('Using items from alternative field');
    }
    
    // Use frontend-calculated values if provided
    if (req.body.credit_amount && !createCreditSaleDto.credit_amount) {
      createCreditSaleDto.credit_amount = req.body.credit_amount;
      console.log('Using frontend credit_amount:', req.body.credit_amount);
    }
    
    if (req.body.monthly_payment && !createCreditSaleDto.monthly_payment) {
      createCreditSaleDto.monthly_payment = req.body.monthly_payment;
      console.log('Using frontend monthly_payment:', req.body.monthly_payment);
    }
    
    if (!Array.isArray(createCreditSaleDto.items)) {
      console.error('Items is not an array, attempting to fix...');
      // Try to parse if it's a string
      if (typeof createCreditSaleDto.items === 'string') {
        try {
          createCreditSaleDto.items = JSON.parse(createCreditSaleDto.items);
        } catch (e) {
          throw new Error('Items field must be a valid array');
        }
      } else {
        // Check if items might be in a different format in the request body
        if (req.body.items && Array.isArray(req.body.items)) {
          createCreditSaleDto.items = req.body.items;
        } else {
          throw new Error('Items field must be an array');
        }
      }
    }
    
    console.log('Final validated items:', createCreditSaleDto.items);
    
    return this.creditSalesService.create(createCreditSaleDto, userId);
  }

  @Get()
  findAll() {
    return this.creditSalesService.findAll();
  }

  @Get('statistics')
  getStatistics() {
    return this.creditSalesService.getStatusStatistics();
  }

  @Get('profit/:year')
  async getProfitByYear(@Param('year') year: string) {
    const yearNumber = parseInt(year, 10);
    if (isNaN(yearNumber)) {
      throw new Error('Invalid year parameter');
    }
    const profit = await this.creditSalesService.calculateProfitByYear(yearNumber);
    return { profit, year: yearNumber };
  }

  @Get('with-calculations')
  async findAllWithCalculations() {
    return this.creditSalesService.findAll();
  }

  @Get('customer/:customerId/with-calculations')
  async findByCustomerWithCalculations(@Param('customerId') customerId: string) {
    return this.creditSalesService.findByCustomer(customerId);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateCreditSaleDto: any) {
    return this.creditSalesService.update(id, updateCreditSaleDto);
  }

  @Get('check-statuses')
  checkAndUpdateStatuses() {
    return this.creditSalesService.checkAndUpdateStatuses();
  }

  @Get('available-ids')
  async getAvailableIds() {
    const creditSales = await this.creditSalesService.findAll();
    return creditSales.map(cs => ({
      id: cs.toString(), // MongoDB document ID
      customer_name: 'Customer Name', // Populated separately
      credit_amount: (cs as any).credit_amount || 0,
      status: (cs as any).status || 'pending',
      total_paid: 0, // Calculate separately
      remaining_amount: (cs as any).credit_amount || 0
    }));
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.creditSalesService.findOne(id);
  }

  @Get('customer/:customerId')
  findByCustomer(@Param('customerId') customerId: string) {
    return this.creditSalesService.findByCustomer(customerId);
  }

  @Put(':id/status')
  updateStatus(@Param('id') id: string, @Body() body: { status: string }) {
    return this.creditSalesService.updateStatus(id, body.status);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.creditSalesService.remove(id);
  }

  @Get('products/:warehouseId')
  async getProductsByWarehouse(@Param('warehouseId') warehouseId: string) {
    return this.creditSalesService.getProductsByWarehouse(warehouseId);
  }

  @Get('products/:warehouseId/detailed')
  async getProductsByWarehouseDetailed(@Param('warehouseId') warehouseId: string) {
    const products = await this.creditSalesService.getProductsByWarehouse(warehouseId);
    return products.map(product => ({
      ...product,
      image: product.image ? `${process.env.HOST_URL || 'http://localhost:3000'}/uploads/${product.image}` : null,
      supplier_price: product.supplier_price ?? null,
      supplier_id: product.supplier_id ?? null,
    }));
  }
}


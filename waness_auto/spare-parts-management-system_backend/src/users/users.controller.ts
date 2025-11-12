import { Controller, UseGuards, Get, Req, NotFoundException, Logger, Body, Patch, Param, Delete } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('users')
export class UsersController {
  private readonly logger = new Logger(UsersController.name);
  constructor(private readonly usersService: UsersService) {}

  

  @Get('profile/:id')
  async getProfileById(@Req() req) {
    const userId = req.params.id;
    this.logger.log(`Recherche du profil pour l'id: ${userId}`);
    const user = await this.usersService.findByIdWithWarehouse(userId);
    this.logger.log(`Résultat de la recherche utilisateur: ${JSON.stringify(user)}`);

    if (!user) {
      this.logger.warn(`Utilisateur non trouvé pour l'id: ${userId}`);
      throw new NotFoundException('Utilisateur non trouvé');
    }

    return {
      id: user._id || user.id,
      name: user.name,
      email: user.email,
      phone_number: user.phone_number,
      role: user.role,
      warehouseName: user.warehouse_id ? 'Warehouse' : null,
      warehouseLocation: user.warehouse_id ? 'Location' : null,
    };
  }

  @Patch('update/:id')
  async updateProfile(@Param('id') id: string, @Body() body: any) {
    const allowedFields = ['name', 'email', 'phone_number'];
    const updateData: any = {};
    for (const key of allowedFields) {
      if (body[key] !== undefined) updateData[key] = body[key];
    }
    const updated = await this.usersService.update(id, updateData);
    return updated;
  }

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async deleteUser(@Param('id') id: string) {
    this.logger.log(`Attempting to delete user with ID: ${id}`);
    
    const result = await this.usersService.deleteUser(id);
    
    if (result.success) {
      this.logger.log(`User ${id} deleted successfully`);
      return { 
        success: true, 
        message: result.message,
        deletedUserId: id 
      };
    } else {
      this.logger.warn(`Failed to delete user ${id}: ${result.message}`);
      throw new NotFoundException(result.message);
    }
  }
}
 



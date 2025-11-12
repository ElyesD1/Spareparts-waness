import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum ProductCategory {
  ELECTRONICS = 'ELECTRONICS',
  AUTOMOTIVE = 'AUTOMOTIVE',
  MECHANICAL = 'MECHANICAL',
  ELECTRICAL = 'ELECTRICAL',
  PLUMBING = 'PLUMBING',
  HVAC = 'HVAC',
  TOOLS = 'TOOLS',
  SAFETY_EQUIPMENT = 'SAFETY_EQUIPMENT',
  LUBRICANTS = 'LUBRICANTS',
  FILTERS = 'FILTERS',
  BELTS = 'BELTS',
  BRAKES = 'BRAKES',
  ENGINE_PARTS = 'ENGINE_PARTS',
  TRANSMISSION = 'TRANSMISSION',
  SUSPENSION = 'SUSPENSION',
  OTHER = 'OTHER'
}

export enum ProductBrand {
  BOSCH = 'BOSCH',
  CONTINENTAL = 'CONTINENTAL',
  VALEO = 'VALEO',
  MANN = 'MANN',
  MAHLE = 'MAHLE',
  NGK = 'NGK',
  DENSO = 'DENSO',
  DELPHI = 'DELPHI',
  SKF = 'SKF',
  TIMKEN = 'TIMKEN',
  GATES = 'GATES',
  DAYCO = 'DAYCO',
  BREMBO = 'BREMBO',
  SACHS = 'SACHS',
  LUK = 'LUK',
  ZF = 'ZF',
  BILSTEIN = 'BILSTEIN',
  KYB = 'KYB',
  MONROE = 'MONROE',
  KONI = 'KONI',
  MOBIL = 'MOBIL',
  CASTROL = 'CASTROL',
  SHELL = 'SHELL',
  TOTAL = 'TOTAL',
  ELF = 'ELF',
  MOTUL = 'MOTUL',
  LIQUI_MOLY = 'LIQUI_MOLY',
  MILLERS = 'MILLERS',
  RED_LINE = 'RED_LINE',
  AMSOIL = 'AMSOIL',
  ROYAL_PURPLE = 'ROYAL_PURPLE',
  PENNZOIL = 'PENNZOIL',
  VALVOLINE = 'VALVOLINE',
  QUAKER_STATE = 'QUAKER_STATE',
  HAVOLINE = 'HAVOLINE',
  OTHER = 'OTHER'
}

export type ProductDocument = Product & Document;

@Schema({ collection: 'products' })
export class Product {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  reference_code: string;

  @Prop({ enum: ProductBrand, default: null })
  brand: ProductBrand;

  @Prop({ enum: ProductCategory, default: null })
  category: ProductCategory;

  @Prop({ default: null })
  image?: string;

  @Prop({ type: Types.ObjectId, ref: 'Supplier', default: null })
  supplier_id: Types.ObjectId;

  @Prop({ required: true, type: Number })
  unit_price: number;

  @Prop({ type: Number, default: null })
  supplier_price: number;

  @Prop({ default: null })
  description: string;

  @Prop({ default: null })
  deletedAt?: Date;

  @Prop({ default: null })
  barcode: string;

  // Helper method to get display name for category
  getCategoryDisplayName(): string {
    if (!this.category) return 'Non catégorisé';
    
    const displayNames: Record<ProductCategory, string> = {
      [ProductCategory.ELECTRONICS]: 'Électronique',
      [ProductCategory.AUTOMOTIVE]: 'Automobile',
      [ProductCategory.MECHANICAL]: 'Mécanique',
      [ProductCategory.ELECTRICAL]: 'Électrique',
      [ProductCategory.PLUMBING]: 'Plomberie',
      [ProductCategory.HVAC]: 'Climatisation',
      [ProductCategory.TOOLS]: 'Outils',
      [ProductCategory.SAFETY_EQUIPMENT]: 'Équipement de sécurité',
      [ProductCategory.LUBRICANTS]: 'Lubrifiants',
      [ProductCategory.FILTERS]: 'Filtres',
      [ProductCategory.BELTS]: 'Courroies',
      [ProductCategory.BRAKES]: 'Freins',
      [ProductCategory.ENGINE_PARTS]: 'Pièces moteur',
      [ProductCategory.TRANSMISSION]: 'Transmission',
      [ProductCategory.SUSPENSION]: 'Suspension',
      [ProductCategory.OTHER]: 'Autre'
    };
    
    return displayNames[this.category] || this.category;
  }

  // Helper method to get display name for brand
  getBrandDisplayName(): string {
    if (!this.brand) return 'Marque non spécifiée';
    
    const displayNames: Record<ProductBrand, string> = {
      [ProductBrand.BOSCH]: 'Bosch',
      [ProductBrand.CONTINENTAL]: 'Continental',
      [ProductBrand.VALEO]: 'Valeo',
      [ProductBrand.MANN]: 'Mann',
      [ProductBrand.MAHLE]: 'Mahle',
      [ProductBrand.NGK]: 'NGK',
      [ProductBrand.DENSO]: 'Denso',
      [ProductBrand.DELPHI]: 'Delphi',
      [ProductBrand.SKF]: 'SKF',
      [ProductBrand.TIMKEN]: 'Timken',
      [ProductBrand.GATES]: 'Gates',
      [ProductBrand.DAYCO]: 'Dayco',
      [ProductBrand.BREMBO]: 'Brembo',
      [ProductBrand.SACHS]: 'Sachs',
      [ProductBrand.LUK]: 'Luk',
      [ProductBrand.ZF]: 'ZF',
      [ProductBrand.BILSTEIN]: 'Bilstein',
      [ProductBrand.KYB]: 'KYB',
      [ProductBrand.MONROE]: 'Monroe',
      [ProductBrand.KONI]: 'Koni',
      [ProductBrand.MOBIL]: 'Mobil',
      [ProductBrand.CASTROL]: 'Castrol',
      [ProductBrand.SHELL]: 'Shell',
      [ProductBrand.TOTAL]: 'Total',
      [ProductBrand.ELF]: 'Elf',
      [ProductBrand.MOTUL]: 'Motul',
      [ProductBrand.LIQUI_MOLY]: 'Liqui Moly',
      [ProductBrand.MILLERS]: 'Millers',
      [ProductBrand.RED_LINE]: 'Red Line',
      [ProductBrand.AMSOIL]: 'Amsoil',
      [ProductBrand.ROYAL_PURPLE]: 'Royal Purple',
      [ProductBrand.PENNZOIL]: 'Pennzoil',
      [ProductBrand.VALVOLINE]: 'Valvoline',
      [ProductBrand.QUAKER_STATE]: 'Quaker State',
      [ProductBrand.HAVOLINE]: 'Havoline',
      [ProductBrand.OTHER]: 'Autre'
    };
    
    return displayNames[this.brand] || this.brand;
  }
}

export const ProductSchema = SchemaFactory.createForClass(Product);
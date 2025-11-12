import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const typeOrmConfig: TypeOrmModuleOptions = {
  type: 'mysql',
  host: 'localhost',
  port: 3306,
  username: 'root',
  password: '',
  database: 'spare_parts_management1',
  autoLoadEntities: true,
  synchronize: false, // Disabled to prevent conflicts
  logging: false, // Disable logging for cleaner output
  migrationsRun: false,
};

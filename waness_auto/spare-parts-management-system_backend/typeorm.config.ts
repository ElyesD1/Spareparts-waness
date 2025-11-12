import { DataSource } from 'typeorm';

export default new DataSource({
  type: 'mysql',
  host: 'localhost',
  port: 3306,
  username: 'root',
  password: '',
  database: 'spare_parts_management1',
  synchronize: true,
  entities: ['src/**/*.entity.ts'],
}); 
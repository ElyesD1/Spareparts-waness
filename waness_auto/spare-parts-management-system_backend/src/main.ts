import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as dotenv from 'dotenv';
import { ValidationPipe } from '@nestjs/common';

dotenv.config(); // Charger les variables d'environnement manuellement

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable global validation pipe with permissive settings
  app.useGlobalPipes(new ValidationPipe({
    whitelist: false,        // Allow unknown properties
    forbidNonWhitelisted: false, // Don't reject unknown properties
    transform: true,         // Transform data types
    transformOptions: {
      enableImplicitConversion: true,
    },
    skipMissingProperties: true, // Skip validation for missing properties
  }));

  // Configure CORS for production (Azure + Vercel)
  app.enableCors({
    origin: [
      'http://localhost:3000',
      'http://localhost:8080',
      /\.vercel\.app$/, // Allow all Vercel deployments and previews
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();

import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET', 'DEFAULT_FALLBACK_SECRET_KEY_12345'),
    });
  }

  async validate(payload: any) {
    // La validation de l'utilisateur se fera ici si nécessaire, 
    // mais pour l'instant, nous retournons le payload décodé.
    return { sub: payload.sub, email: payload.email, role: payload.role };
  }
}

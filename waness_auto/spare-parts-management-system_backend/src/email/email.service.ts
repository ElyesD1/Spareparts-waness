import { Injectable } from '@nestjs/common';
import * as Brevo from '@getbrevo/brevo';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  private apiInstance: Brevo.TransactionalEmailsApi;
  private readonly emailFrom: string;

  constructor(private configService: ConfigService) {
    console.log('📧 Initialisation du EmailService...');

    const brevoApiKey = this.configService.getOrThrow<string>('BREVO_API_KEY');
    this.emailFrom = this.configService.getOrThrow<string>('EMAIL_FROM');

    this.apiInstance = new Brevo.TransactionalEmailsApi();
    this.apiInstance.setApiKey(
      Brevo.TransactionalEmailsApiApiKeys.apiKey,
      brevoApiKey,
    );
    console.log('✅ Brevo API initialisée');
  }

  async sendOtp(email: string, otp: string) {
    console.log(`📩 Envoi OTP à: ${email} | OTP: ${otp}`);

    const emailData: Brevo.SendSmtpEmail = {
      sender: { email: this.emailFrom, name: 'Societe Wanes_Auto' },
      to: [{ email }],
      subject: 'Votre code de vérification (OTP)',
      htmlContent: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; border: 1px solid #eee; border-radius: 8px; padding: 24px; background: #fafbfc;">
          <h2 style="color: #2d7ff9; text-align: center;">Wanes Auto </h2>
          <p>Bonjour,</p>
          <p>Vous avez demandé à recevoir un code de vérification pour sécuriser votre compte.</p>
          <div style="text-align: center; margin: 32px 0;">
            <span style="display: inline-block; font-size: 2rem; letter-spacing: 8px; background: #f3f6fa; border-radius: 6px; padding: 16px 32px; color: #2d7ff9; font-weight: bold; border: 1px dashed #2d7ff9;">
              ${otp}
            </span>
          </div>
          <p>Ce code est valable 10 minutes. Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet email.</p>
          <hr style="margin: 32px 0;">
          <p style="font-size: 0.9em; color: #888; text-align: center;">
            Besoin d'aide ? Contactez-nous à <a href="mailto:support@wanesAuto.com">support@wanesAuto.com</a>
          </p>
        </div>
      `,
    };

    try {
      const response = await this.apiInstance.sendTransacEmail(emailData);
      console.log(`✅ Email envoyé à ${email} | Message ID: ${response.body.messageId}`);
    } catch (error) {
      if (error.response) {
      } else {
        console.error('❌ Erreur lors de l\'envoi de l\'email:', error);}
      throw error;
    }
  }
}


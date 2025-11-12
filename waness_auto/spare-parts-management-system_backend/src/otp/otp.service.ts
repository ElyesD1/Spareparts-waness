import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as otpGenerator from 'otp-generator';
import * as bcrypt from 'bcrypt';
import { Otp, OtpDocument } from './entities/otp.entity';
import { EmailService } from '../email/email.service'; 
import { User, UserDocument } from 'src/users/user.entity';
import { ResetPasswordDto } from 'src/auth/dto/reset-password.dto';

@Injectable()
export class OtpService {
  constructor(
    @InjectModel(Otp.name)
    private readonly otpModel: Model<OtpDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
    private readonly emailService: EmailService,
  ) {}

  async forgotPasswordOtpByEmail(email: string) {
    const user = await this.userModel.findOne({ email }).exec();
    if (!user) throw new HttpException('User not found', HttpStatus.NOT_FOUND);

    const otpNumber = otpGenerator.generate(6, { digits: true, upperCaseAlphabets: false, lowerCaseAlphabets: false, specialChars: false });
    const otpHash = await bcrypt.hash(otpNumber, 10);

    const userId = (user as any)._id.toString();
    await this.otpModel.deleteMany({ userId: new Types.ObjectId(userId) }).exec();

    const otp = new this.otpModel({
      otp: otpHash,
      userId: new Types.ObjectId(userId),
      user: new Types.ObjectId(userId),
      otpExpires: new Date(Date.now() + 10 * 60 * 1000),
    });

    console.log('⏳ Tentative de sauvegarde de l\'OTP en base de données...', otp);

    try {
      await otp.save();
      console.log('✅ OTP sauvegardé avec succès !');
    } catch (dbError) {
      console.error('❌ ERREUR LORS DE LA SAUVEGARDE DE L\'OTP:', dbError);
      throw new HttpException('Impossible de sauvegarder l\'OTP', HttpStatus.INTERNAL_SERVER_ERROR);
    }

    await this.emailService.sendOtp(email, otpNumber);

    return { message: 'OTP sent successfully', userId };
  }

  async verifyOtp(email: string, otpReceived: string) {
    const user = await this.userModel.findOne({ email }).exec();
    if (!user) throw new HttpException('User not found', HttpStatus.NOT_FOUND);

    const userId = (user as any)._id.toString();
    const otpRecord = await this.otpModel.findOne({ 
      userId: new Types.ObjectId(userId),
    }).exec();
    
    if (!otpRecord) throw new HttpException('OTP not found', HttpStatus.NOT_FOUND);

    if (new Date() > otpRecord.otpExpires) throw new HttpException('OTP has expired', HttpStatus.BAD_REQUEST);

    const isValidOtp = await bcrypt.compare(otpReceived, otpRecord.otp);
    if (!isValidOtp) throw new HttpException('Invalid OTP', HttpStatus.BAD_REQUEST);

    // Optionnel : supprimer l'OTP après vérification
    await this.otpModel.findByIdAndDelete((otpRecord as any)._id).exec();

    return { message: 'OTP verified successfully', user };
  }

  async resetPassword(dto: ResetPasswordDto) {
    console.log('--- Début du processus de réinitialisation de mot de passe ---');
    const { userId, otp, newPassword, confirmPassword } = dto;
    console.log(`1. Données reçues: userId=${userId}, otp=${otp}`);

    if (newPassword !== confirmPassword) {
      console.error('❌ ECHEC: Les mots de passe ne correspondent pas.');
      throw new HttpException('Les mots de passe ne correspondent pas', HttpStatus.BAD_REQUEST);
    }

    console.log('2. Recherche de l\'utilisateur...');
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      console.error(`❌ ECHEC: Utilisateur avec ID ${userId} introuvable.`);
      throw new HttpException('Utilisateur introuvable', HttpStatus.NOT_FOUND);
    }
    console.log(`✅ Utilisateur trouvé: ${user.email}`);

    console.log('3. Recherche de l\'OTP...');
    const otpRecord = await this.otpModel.findOne({ userId: new Types.ObjectId(userId) }).exec();
    if (!otpRecord) {
      console.error('❌ ECHEC: Aucun OTP trouvé pour cet utilisateur.');
      throw new HttpException('OTP introuvable', HttpStatus.NOT_FOUND);
    }
    console.log('✅ OTP trouvé.');

    console.log('4. Vérification de l\'expiration de l\'OTP...');
    if (new Date() > otpRecord.otpExpires) {
      console.error('❌ ECHEC: L\'OTP a expiré.');
      throw new HttpException('L\'OTP a expiré', HttpStatus.BAD_REQUEST);
    }
    console.log('✅ L\'OTP est encore valide.');

    console.log('5. Comparaison de l\'OTP...');
    const isValidOtp = await bcrypt.compare(otp, otpRecord.otp);
    if (!isValidOtp) {
      console.error('❌ ECHEC: OTP invalide.');
      throw new HttpException('OTP invalide', HttpStatus.BAD_REQUEST);
    }
    console.log('✅ OTP validé avec succès.');

    console.log('6. Hachage du nouveau mot de passe...');
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    console.log('✅ Mot de passe haché.');

    console.log('7. Mise à jour du mot de passe utilisateur...');
    user.password_hash = hashedPassword;
    await user.save();
    console.log('✅ Mot de passe mis à jour avec succès.');

    console.log('8. Suppression de l\'OTP...');
    await this.otpModel.findByIdAndDelete((otpRecord as any)._id).exec();
    console.log('✅ OTP supprimé.');

    console.log('--- Processus de réinitialisation terminé avec succès ---');
    return { message: 'Mot de passe réinitialisé avec succès' };
  }
}


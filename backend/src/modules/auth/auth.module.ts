import { Module } from '@nestjs/common';
import { FirebaseModule } from '../../firebase/firebase.module';
import { AuthController, UsersController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  imports: [FirebaseModule],
  controllers: [AuthController, UsersController],
  providers: [AuthService],
  exports: [AuthService],
})
export class AuthModule {}


import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'david.vance@bhp.com' })
  email: string;

  @ApiProperty({ example: 'SecurePass123!' })
  password: string;
}


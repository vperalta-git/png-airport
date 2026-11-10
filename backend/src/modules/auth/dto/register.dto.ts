import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'Capt. David Vance' })
  name: string;

  @ApiProperty({ example: 'david.vance@bhp.com' })
  email: string;

  @ApiProperty({ example: 'SecurePass123!' })
  password: string;

  @ApiProperty({ example: '+675 7123 4567' })
  whatsapp_number: string;

  @ApiPropertyOptional({ example: '+675 7123 4567' })
  phone?: string;

  @ApiPropertyOptional({ example: 'BHP Minerals PNG / Ok Tedi Exploration' })
  company?: string;

  @ApiPropertyOptional({ example: 'passenger', default: 'passenger' })
  role?: string;
}


import { Test, TestingModule } from '@nestjs/testing';
import { AvailabilityService } from './availability.service';
import { ResourcesService } from '../resources/resources.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { VehicleCategoryEnum, SecurityEscortTypeEnum } from '../quotations/dto/create-quote.dto';

describe('AvailabilityService', () => {
  let service: AvailabilityService;

  const mockFirebaseService = {
    firestore: {
      collection: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({ docs: [], empty: true }),
        doc: jest.fn().mockReturnValue({
          set: jest.fn().mockResolvedValue(true),
        }),
      }),
      runTransaction: jest.fn().mockImplementation(async (cb) => {
        return cb({
          set: jest.fn(),
          get: jest.fn(),
        });
      }),
    },
  };

  const mockResourcesService = {
    listVehicles: jest.fn().mockResolvedValue([
      {
        id: 'veh_toyota_lc79_01',
        registrationPlate: 'LAE-8821',
        make: 'Toyota',
        model: 'LandCruiser 79',
        category: VehicleCategoryEnum.HEAVY_4WD,
        status: 'ACTIVE',
      },
    ]),
    listDrivers: jest.fn().mockResolvedValue([
      {
        id: 'driver_john_kandep',
        fullName: 'John Kandep',
        phone: '+675 7123 4567',
        status: 'AVAILABLE',
      },
    ]),
    listSecurityPersonnel: jest.fn().mockResolvedValue([
      {
        id: 'guard_michael_toru',
        fullName: 'Michael Toru',
        callsign: 'VIPER-1',
        status: 'AVAILABLE',
      },
    ]),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AvailabilityService,
        { provide: FirebaseService, useValue: mockFirebaseService },
        { provide: ResourcesService, useValue: mockResourcesService },
      ],
    }).compile();

    service = module.get<AvailabilityService>(AvailabilityService);
  });

  it('should correctly calculate trip window with transit and buffer time', () => {
    const pickupTime = '2026-11-15T09:00:00.000Z';
    const window = service.calculateTripWindow(pickupTime, 45);

    expect(window.startTime).toBe(pickupTime);
    const startMs = new Date(pickupTime).getTime();
    const endMs = new Date(window.endTime).getTime();
    expect(endMs).toBeGreaterThan(startMs);
  });

  it('should evaluate resource availability without conflicts when no reservations exist', async () => {
    const result = await service.checkAvailability(
      VehicleCategoryEnum.HEAVY_4WD,
      SecurityEscortTypeEnum.ARMED_ESCORT_CHASE_VEHICLE,
      '2026-11-15T09:00:00.000Z',
    );

    expect(result.isAvailable).toBe(true);
    expect(result.vehicle?.id).toBe('veh_toyota_lc79_01');
    expect(result.driver?.id).toBe('driver_john_kandep');
    expect(result.security?.id).toBe('guard_michael_toru');
    expect(result.conflicts.length).toBe(0);
  });
});


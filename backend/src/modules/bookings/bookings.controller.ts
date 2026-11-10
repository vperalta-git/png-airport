import { Controller, Get, Post, Patch, Param, Body } from "@nestjs/common";
import { BookingRequest } from "@png-transfer/types";
import { BookingsService } from "./bookings.service";
import { CanonicalBookingPipe } from "../../contracts/canonical.pipe";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { Workflow } from "../../common/workflow";
@Controller("bookings")
@Workflow()
export class BookingsController {
  constructor(private readonly bookings: BookingsService) {}
  @Post() create(
    @Body(new CanonicalBookingPipe()) b: BookingRequest,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.create(b, a);
  }
  @Get() list(@CurrentUser() a: AuthenticatedUser) {
    return this.bookings.list(a);
  }
  @Get(":id") get(
    @Param("id") id: string,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.getBooking(id, a);
  }
  @Get(":id/details") details(
    @Param("id") id: string,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.details(id, a);
  }
  @Get(":id/pickup-credential") code(
    @Param("id") id: string,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.pickupCredential(id, a);
  }
  @Patch(":id/status") status(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.status(id, v, a);
  }
  @Post(":id/verify-passenger") verify(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.verify(id, v, a);
  }
  @Post(":id/reset-otp") reset(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.bookings.resetPickup(id, v, a);
  }
}

import 'package:equatable/equatable.dart';
import '../models/corporate_booking.dart';
import '../models/corporate_passenger.dart';
import '../models/corporate_invoice.dart';
import '../models/corporate_rate.dart';

enum CorporateLoadingStatus { initial, loading, loaded, error }

class CorporateState extends Equatable {
  final CorporateLoadingStatus status;
  final String companyName;
  final double creditLimitPgk;
  final double billedThisMonthPgk;
  final List<CorporateBooking> bookings;
  final List<CorporatePassenger> passengers;
  final List<CorporateInvoice> invoices;
  final List<CorporateRateItem> rates;
  final String? lastNotification;
  final String? errorMessage;

  const CorporateState({
    this.status = CorporateLoadingStatus.initial,
    this.companyName = 'PNG Mining & Exploration Logistics Ltd',
    this.creditLimitPgk = 50000.0,
    this.billedThisMonthPgk = 16940.0,
    this.bookings = const [],
    this.passengers = const [],
    this.invoices = const [],
    this.rates = const [],
    this.lastNotification,
    this.errorMessage,
  });

  int get pendingApprovalsCount =>
      bookings.where((b) => b.status == CorporateBookingStatus.pendingApproval).length;

  int get activeTransfersCount => bookings.where((b) =>
      b.status == CorporateBookingStatus.approved ||
      b.status == CorporateBookingStatus.dispatched ||
      b.status == CorporateBookingStatus.inTransit).length;

  CorporateState copyWith({
    CorporateLoadingStatus? status,
    String? companyName,
    double? creditLimitPgk,
    double? billedThisMonthPgk,
    List<CorporateBooking>? bookings,
    List<CorporatePassenger>? passengers,
    List<CorporateInvoice>? invoices,
    List<CorporateRateItem>? rates,
    String? lastNotification,
    String? errorMessage,
  }) {
    return CorporateState(
      status: status ?? this.status,
      companyName: companyName ?? this.companyName,
      creditLimitPgk: creditLimitPgk ?? this.creditLimitPgk,
      billedThisMonthPgk: billedThisMonthPgk ?? this.billedThisMonthPgk,
      bookings: bookings ?? this.bookings,
      passengers: passengers ?? this.passengers,
      invoices: invoices ?? this.invoices,
      rates: rates ?? this.rates,
      lastNotification: lastNotification,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    companyName,
    bookings,
    passengers,
    invoices,
    lastNotification,
  ];
}


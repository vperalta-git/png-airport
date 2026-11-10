import 'package:equatable/equatable.dart';

enum InvoiceStatus { pending, approved, paid, overdue }

class CorporateInvoice extends Equatable {
  final String invoiceNumber;
  final String billingPeriod;
  final String poNumber;
  final int totalTransfers;
  final double subtotalPgk;
  final double gstPgk;
  final double totalPgk;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;

  const CorporateInvoice({
    required this.invoiceNumber,
    required this.billingPeriod,
    required this.poNumber,
    required this.totalTransfers,
    required this.subtotalPgk,
    required this.gstPgk,
    required this.totalPgk,
    required this.status,
    required this.issueDate,
    required this.dueDate,
  });

  factory CorporateInvoice.fromJson(Map<String, dynamic> json) {
    InvoiceStatus parseStatus(String? s) {
      switch (s) {
        case 'paid':
          return InvoiceStatus.paid;
        case 'overdue':
          return InvoiceStatus.overdue;
        case 'approved':
          return InvoiceStatus.approved;
        default:
          return InvoiceStatus.pending;
      }
    }

    return CorporateInvoice(
      invoiceNumber: json['invoice_number'] as String? ?? 'INV-PNG-2026-0001',
      billingPeriod: json['billing_period'] as String? ?? 'November 2026',
      poNumber: json['po_number'] as String? ?? 'PO-2026-PNG-001',
      totalTransfers: json['total_transfers'] as int? ?? 1,
      subtotalPgk: (json['subtotal_pgk'] as num?)?.toDouble() ?? 5000.0,
      gstPgk: (json['gst_pgk'] as num?)?.toDouble() ?? 500.0,
      totalPgk: (json['total_pgk'] as num?)?.toDouble() ?? 5500.0,
      status: parseStatus(json['status'] as String?),
      issueDate: DateTime.tryParse(json['issue_date']?.toString() ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toJson() => {
    'invoice_number': invoiceNumber,
    'billing_period': billingPeriod,
    'po_number': poNumber,
    'total_transfers': totalTransfers,
    'subtotal_pgk': subtotalPgk,
    'gst_pgk': gstPgk,
    'total_pgk': totalPgk,
    'status': status.name,
    'issue_date': issueDate.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
  };

  @override
  List<Object?> get props => [invoiceNumber, poNumber, totalPgk, status];
}


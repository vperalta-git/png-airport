import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../blocs/corporate_state.dart';
import '../../models/corporate_invoice.dart';

class InvoicesTab extends StatelessWidget {
  final CorporateState state;

  const InvoicesTab({
    super.key,
    required this.state,
  });

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.tealAccent;
      case InvoiceStatus.approved:
        return Colors.blueAccent;
      case InvoiceStatus.pending:
        return Colors.orangeAccent;
      case InvoiceStatus.overdue:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    final totalInvoiced = state.invoices.fold<double>(0.0, (sum, inv) => sum + inv.totalPgk);
    final totalGst = state.invoices.fold<double>(0.0, (sum, inv) => sum + inv.gstPgk);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVOICES & STATEMENTS OF ACCOUNT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG Internal Revenue Commission (IRC) compliant tax invoices, PO reconciliations, and GST breakdowns.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.tealAccent,
                  side: const BorderSide(color: Colors.tealAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export Consolidated Statement'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Consolidated Corporate Billing Statement (IRC Tax Invoice) exported to PDF.'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Billing Summary KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Invoiced (YTD)',
                  '${currency.format(totalInvoiced)} PGK',
                  'Inclusive of all settled transfers',
                  Icons.receipt_long_outlined,
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'PNG 10% GST Remitted',
                  '${currency.format(totalGst)} PGK',
                  'Statutory IRC tax compliance',
                  Icons.account_balance_outlined,
                  Colors.tealAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Current Billing Cycle',
                  '${currency.format(state.billedThisMonthPgk)} PGK',
                  'Under PO: PO-2026-MMR-CORP',
                  Icons.timer_outlined,
                  Colors.amberAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Statements Table Section
          const Text(
            'BILLING STATEMENTS & TAX INVOICES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF151E32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1C2742)),
              columns: const [
                DataColumn(label: Text('TAX INVOICE #', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('BILLING PERIOD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('PO NUMBER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('TRANSFERS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('SUBTOTAL (PGK)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('GST 10% (PGK)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('TOTAL (PGK)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('STATUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('ACTION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: state.invoices.map((inv) {
                final statusColor = _getStatusColor(inv.status);
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        inv.invoiceNumber,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(inv.billingPeriod, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Text('Due: ${dateFormat.format(inv.dueDate)}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(inv.poNumber, style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'monospace')),
                    ),
                    DataCell(
                      Text('${inv.totalTransfers} Flights', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    DataCell(
                      Text(currency.format(inv.subtotalPgk), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    DataCell(
                      Text(currency.format(inv.gstPgk), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                    DataCell(
                      Text(
                        currency.format(inv.totalPgk),
                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          inv.status.name.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.blueAccent, size: 18),
                        tooltip: 'Download Tax Invoice PDF',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invoice ${inv.invoiceNumber} downloaded with IRC Tax Seal.'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151E32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}


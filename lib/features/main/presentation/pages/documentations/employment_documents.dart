import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// COLOR PALETTE & DESIGN CONSTANTS (Matched with Staff Master)
// =============================================================================
const Color kBrandBlue = Color(0xFF0066B3);
const Color kBrandRed = Color(0xFFD32027);
const Color kDarkSlate = Color(0xFF0B0E14);
const Color kTextMuted = Color(0xFF8B949E);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFF8FAFC);

const Map<String, String> kDocTypeMap = {
  "OFFER_LETTER": "Offer Letter",
  "APPOINTMENT_LETTER": "Appointment / Joining Letter",
  "EXPERIENCE_LETTER": "Work Experience Certificate",
  "RELIEVING_LETTER": "Relieving Letter",
  "INTERNSHIP_CERTIFICATE": "Internship Completion Certificate",
  "INCREMENT_LETTER": "Salary Increment Letter",
};

// =============================================================================
// 1. DATA ENTITIES & REPOSITORY
// =============================================================================
class EmploymentDocItem {
  final String id;
  final String documentNumber;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String companyName;
  final String documentType;
  final String documentTypeDisplay;
  final String issueDate;
  final String status;
  final String designationSnapshot;
  final String joiningDateSnapshot;
  final String? relievingDateSnapshot;
  final double ctcSnapshot;
  final String? customLetterBody;
  final String? conductRating;
  final String? generatedPdf;
  final String verificationToken;

  const EmploymentDocItem({
    required this.id,
    required this.documentNumber,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.companyName,
    required this.documentType,
    required this.documentTypeDisplay,
    required this.issueDate,
    required this.status,
    required this.designationSnapshot,
    required this.joiningDateSnapshot,
    this.relievingDateSnapshot,
    required this.ctcSnapshot,
    this.customLetterBody,
    this.conductRating,
    this.generatedPdf,
    required this.verificationToken,
  });

  factory EmploymentDocItem.fromJson(Map<String, dynamic> json) {
    return EmploymentDocItem(
      id: (json['id'] ?? '').toString(),
      documentNumber: json['document_number'] ?? 'N/A',
      employeeId: (json['employee'] ?? '').toString(),
      employeeName: json['employee_name'] ?? 'Staff Member',
      employeeCode: json['employee_code'] ?? 'EMP',
      companyName: json['company_name'] ?? 'Softwing Tech Labs',
      documentType: json['document_type'] ?? 'OFFER_LETTER',
      documentTypeDisplay: json['document_type_display'] ?? json['document_type'] ?? 'Official Document',
      issueDate: json['issue_date'] ?? '',
      status: json['status'] ?? 'ISSUED',
      designationSnapshot: json['designation_snapshot'] ?? 'Staff',
      joiningDateSnapshot: json['joining_date_snapshot'] ?? '',
      relievingDateSnapshot: json['relieving_date_snapshot'],
      ctcSnapshot: double.tryParse((json['ctc_snapshot'] ?? 0).toString()) ?? 0.0,
      customLetterBody: json['custom_letter_body'],
      conductRating: json['conduct_rating'] ?? 'Good and Professional',
      generatedPdf: json['generated_pdf'],
      verificationToken: (json['verification_token'] ?? '').toString(),
    );
  }
}

class EmploymentDocRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<EmploymentDocItem>> fetchDocuments({String? search, String? docType}) async {
    final Map<String, dynamic> params = {};
    if (docType != null && docType != 'ALL') params['doc_type'] = docType;

    final res = await apiClient.get('/api/hrms/documents/', query: params);
    final dynamic data = res.data;
    List rawList = [];
    if (data is Map && data.containsKey('data')) {
      rawList = data['data'] as List;
    } else if (data is Map && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList.map((e) => EmploymentDocItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final res = await apiClient.get('/api/hrms/employees/');
    final dynamic data = res.data;
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    } else if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> issueLetter(Map<String, dynamic> payload) async {
    await apiClient.post('/api/hrms/documents/issue-letter/', data: payload);
  }

  Future<void> deleteDocument(String id) async {
    await apiClient.delete('/api/hrms/documents/$id/');
  }
}

// =============================================================================
// 2. BLOC STATE MANAGEMENT ENGINE
// =============================================================================
abstract class DocRegistryEvent {}

class LoadDocRegistryEvent extends DocRegistryEvent {}

class SearchDocRegistryEvent extends DocRegistryEvent {
  final String query;
  SearchDocRegistryEvent(this.query);
}

class FilterDocTypeEvent extends DocRegistryEvent {
  final String docType;
  FilterDocTypeEvent(this.docType);
}

class SubmitIssueLetterEvent extends DocRegistryEvent {
  final Map<String, dynamic> payload;
  SubmitIssueLetterEvent(this.payload);
}

class DeleteIssuedDocEvent extends DocRegistryEvent {
  final String id;
  DeleteIssuedDocEvent(this.id);
}

abstract class DocRegistryState {}

class DocRegistryLoading extends DocRegistryState {}

class DocRegistryLoaded extends DocRegistryState {
  final List<EmploymentDocItem> documents;
  final List<Map<String, dynamic>> employees;
  final String activeFilter;
  final String searchQuery;
  final bool isBusy;

  DocRegistryLoaded({
    required this.documents,
    required this.employees,
    this.activeFilter = 'ALL',
    this.searchQuery = '',
    this.isBusy = false,
  });

  DocRegistryLoaded copyWith({
    List<EmploymentDocItem>? documents,
    List<Map<String, dynamic>>? employees,
    String? activeFilter,
    String? searchQuery,
    bool? isBusy,
  }) {
    return DocRegistryLoaded(
      documents: documents ?? this.documents,
      employees: employees ?? this.employees,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

class DocRegistryError extends DocRegistryState {
  final String message;
  DocRegistryError(this.message);
}

class DocRegistryBloc extends Bloc<DocRegistryEvent, DocRegistryState> {
  final EmploymentDocRepository repository;
  List<EmploymentDocItem> _cachedDocs = [];
  List<Map<String, dynamic>> _cachedEmployees = [];
  String _currentFilter = 'ALL';
  String _currentSearch = '';

  DocRegistryBloc(this.repository) : super(DocRegistryLoading()) {
    on<LoadDocRegistryEvent>((event, emit) async {
      try {
        final results = await Future.wait([
          repository.fetchDocuments(),
          repository.fetchEmployees(),
        ]);

        _cachedDocs = results[0] as List<EmploymentDocItem>;
        _cachedEmployees = results[1] as List<Map<String, dynamic>>;

        _applyFilters(emit);
      } catch (e) {
        emit(DocRegistryError("Failed to synchronize documents registry: $e"));
      }
    });

    on<SearchDocRegistryEvent>((event, emit) {
      _currentSearch = event.query.toLowerCase().trim();
      _applyFilters(emit);
    });

    on<FilterDocTypeEvent>((event, emit) {
      _currentFilter = event.docType;
      _applyFilters(emit);
    });

    on<SubmitIssueLetterEvent>((event, emit) async {
      if (state is DocRegistryLoaded) {
        emit((state as DocRegistryLoaded).copyWith(isBusy: true));
        try {
          await repository.issueLetter(event.payload);
          add(LoadDocRegistryEvent());
        } catch (e) {
          emit(DocRegistryError("Could not issue official document: $e"));
        }
      }
    });

    on<DeleteIssuedDocEvent>((event, emit) async {
      if (state is DocRegistryLoaded) {
        emit((state as DocRegistryLoaded).copyWith(isBusy: true));
        try {
          await repository.deleteDocument(event.id);
          add(LoadDocRegistryEvent());
        } catch (e) {
          emit(DocRegistryError("Failed to delete document: $e"));
        }
      }
    });
  }

  void _applyFilters(Emitter<DocRegistryState> emit) {
    final filtered = _cachedDocs.where((doc) {
      final matchSearch = doc.employeeName.toLowerCase().contains(_currentSearch) ||
          doc.employeeCode.toLowerCase().contains(_currentSearch) ||
          doc.documentNumber.toLowerCase().contains(_currentSearch) ||
          doc.designationSnapshot.toLowerCase().contains(_currentSearch);

      final matchType = _currentFilter == 'ALL' || doc.documentType == _currentFilter;

      return matchSearch && matchType;
    }).toList();

    emit(DocRegistryLoaded(
      documents: filtered,
      employees: _cachedEmployees,
      activeFilter: _currentFilter,
      searchQuery: _currentSearch,
      isBusy: false,
    ));
  }
}

// =============================================================================
// 3. MAIN REGISTRY VIEW CANVAS
// =============================================================================
class EmploymentDocumentScreen extends StatelessWidget {
  const EmploymentDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return BlocProvider(
      create: (context) => DocRegistryBloc(EmploymentDocRepository())..add(LoadDocRegistryEvent()),
      child: Scaffold(
        backgroundColor: kSurfaceBg,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context, isMobile),
              const SizedBox(height: 14),
              _buildMetricsRibbon(isMobile),
              const SizedBox(height: 14),
              Expanded(
                child: BlocConsumer<DocRegistryBloc, DocRegistryState>(
                  listener: (context, state) {
                    if (state is DocRegistryError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: kBrandRed, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is DocRegistryLoading) {
                      return const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2));
                    }
                    if (state is DocRegistryLoaded) {
                      return _buildTableContainer(context, state, isMobile);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "EMPLOYMENT DOCUMENTS & LETTERS REGISTRY",
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.6),
            ),
            SizedBox(height: 2),
            Text(
              "Generate, Sign, and Download Official Offer, Appointment, Experience, and Relieving Certificates",
              style: TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Builder(
          builder: (btnCtx) => ElevatedButton.icon(
            onPressed: () {
              final state = btnCtx.read<DocRegistryBloc>().state;
              if (state is DocRegistryLoaded) {
                if (state.employees.isEmpty) {
                  ScaffoldMessenger.of(btnCtx).showSnackBar(
                    const SnackBar(content: Text("Onboard employees in Staff Master first."), backgroundColor: kBrandRed),
                  );
                  return;
                }
                showIssueLetterModal(btnCtx, state.employees);
              }
            },
            icon: const Icon(Icons.post_add_rounded, size: 15),
            label: Text(
              isMobile ? "ISSUE" : "GENERATE OFFICIAL LETTER",
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRibbon(bool isMobile) {
    return BlocBuilder<DocRegistryBloc, DocRegistryState>(
      builder: (context, state) {
        int totalIssued = 0;
        int appointments = 0;
        int experiences = 0;
        int relieving = 0;

        if (state is DocRegistryLoaded) {
          totalIssued = state.documents.length;
          appointments = state.documents.where((d) => d.documentType == "APPOINTMENT_LETTER" || d.documentType == "OFFER_LETTER").length;
          experiences = state.documents.where((d) => d.documentType == "EXPERIENCE_LETTER").length;
          relieving = state.documents.where((d) => d.documentType == "RELIEVING_LETTER").length;
        }

        final items = [
          _metricCard("TOTAL ISSUED LETTERS", "$totalIssued", Icons.mark_email_read_outlined, kBrandBlue),
          _metricCard("OFFER & APPOINTMENTS", "$appointments", Icons.assignment_ind_outlined, const Color(0xFF10B981)),
          _metricCard("EXPERIENCE CERTIFICATES", "$experiences", Icons.workspace_premium_outlined, const Color(0xFFF59E0B)),
          _metricCard("RELIEVING LETTERS", "$relieving", Icons.exit_to_app_rounded, const Color(0xFF8B5CF6)),
        ];

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: items.map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList()),
          );
        }

        return Row(children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList());
      },
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, color: kTextMuted, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kDarkSlate)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTableContainer(BuildContext context, DocRegistryLoaded state, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFilterSearchStrip(context, state),
          const Divider(height: 1),
          Expanded(
            child: state.documents.isEmpty
                ? const Center(child: Text("No employment letters matching the criteria.", style: TextStyle(color: kTextMuted, fontSize: 11.5)))
                : isMobile
                ? _buildMobileView(context, state)
                : _buildDesktopTableView(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSearchStrip(BuildContext context, DocRegistryLoaded state) {
    final bloc = context.read<DocRegistryBloc>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 11.5),
                onChanged: (v) => bloc.add(SearchDocRegistryEvent(v)),
                decoration: const InputDecoration(
                  hintText: "Search by Doc Ref No, Employee Name, Emp Code, Role...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 15, color: kBrandBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 6,
            children: ["ALL", "APPOINTMENT_LETTER", "OFFER_LETTER", "EXPERIENCE_LETTER", "RELIEVING_LETTER"].map((filterKey) {
              final isSelected = state.activeFilter == filterKey;
              final label = filterKey == "ALL" ? "ALL LETTERS" : kDocTypeMap[filterKey] ?? filterKey;
              return ChoiceChip(
                label: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kDarkSlate)),
                selected: isSelected,
                selectedColor: kBrandBlue,
                backgroundColor: kSurfaceBg,
                onSelected: (_) => bloc.add(FilterDocTypeEvent(filterKey)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableView(BuildContext context, DocRegistryLoaded state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: kCardBg,
          child: Row(
            children: [
              _hCell("DOCUMENT IDENTIFIER", 5),
              _hCell("EMPLOYEE & IDENTITY", 5),
              _hCell("ROLE SNAPSHOT", 4),
              _hCell("DATE OF ISSUE", 3),
              _hCell("STATUS", 2),
              _hCell("ACTIONS", 4, true),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: state.documents.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              final doc = state.documents[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: kBrandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                            child: const Icon(Icons.description_outlined, color: kBrandBlue, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc.documentNumber, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kBrandBlue)),
                                Text(doc.documentTypeDisplay, style: const TextStyle(fontSize: 9.5, color: kDarkSlate, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.employeeName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                          Text(doc.employeeCode, style: const TextStyle(fontSize: 9, color: kTextMuted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.designationSnapshot, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDarkSlate)),
                          Text("Joined: ${doc.joiningDateSnapshot}", style: const TextStyle(fontSize: 9, color: kTextMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        doc.issueDate,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(3)),
                          child: Text(doc.status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.green.shade800, letterSpacing: 0.3)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _actionBtn(Icons.visibility_outlined, "Preview Letter Details", () => showLetterPreviewModal(context, doc)),
                          const SizedBox(width: 4),
                          if (doc.generatedPdf != null && doc.generatedPdf!.isNotEmpty)
                            _actionBtn(
                              Icons.download_rounded,
                              "Download / Print Official PDF",
                                  () => launchUrl(Uri.parse(doc.generatedPdf!), mode: LaunchMode.externalApplication),
                              color: const Color(0xFF10B981),
                            ),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.delete_outline_rounded, "Purge Letter Record", () => _confirmDelete(context, doc), color: kBrandRed),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, DocRegistryLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.documents.length,
      itemBuilder: (ctx, i) {
        final doc = state.documents[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(doc.documentNumber, style: const TextStyle(fontSize: 9.5, color: kBrandBlue, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(3)),
                      child: Text(doc.status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(doc.employeeName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                Text("${doc.documentTypeDisplay} • ${doc.designationSnapshot}", style: const TextStyle(fontSize: 10, color: kTextMuted)),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Issue Date: ${doc.issueDate}", style: const TextStyle(fontSize: 9.5, color: kDarkSlate)),
                    Row(
                      children: [
                        TextButton.icon(onPressed: () => showLetterPreviewModal(context, doc), icon: const Icon(Icons.visibility, size: 12), label: const Text("VIEW", style: TextStyle(fontSize: 9.5))),
                        if (doc.generatedPdf != null)
                          IconButton(
                            icon: const Icon(Icons.download_rounded, size: 14, color: Color(0xFF10B981)),
                            onPressed: () => launchUrl(Uri.parse(doc.generatedPdf!), mode: LaunchMode.externalApplication),
                          ),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 14, color: kBrandRed), onPressed: () => _confirmDelete(context, doc)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap, {Color? color}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: (color ?? Colors.blueGrey).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 13.5, color: color ?? Colors.blueGrey.shade700),
        ),
      ),
    );
  }

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(
    flex: f,
    child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: kTextMuted, letterSpacing: 0.5)),
  );

  void _confirmDelete(BuildContext context, EmploymentDocItem doc) {
    final bloc = context.read<DocRegistryBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kBrandRed, size: 18),
            SizedBox(width: 8),
            Text("Purge Letter Record?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandRed)),
          ],
        ),
        content: Text("Are you sure you want to delete ${doc.documentNumber} issued to ${doc.employeeName}? This action cannot be reversed.", style: const TextStyle(fontSize: 11.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kBrandRed, foregroundColor: Colors.white),
            onPressed: () {
              bloc.add(DeleteIssuedDocEvent(doc.id));
              Navigator.pop(ctx);
            },
            child: const Text("PURGE RECORD"),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. MODAL: ISSUE OFFICIAL LETTER FORM
// =============================================================================
void showIssueLetterModal(BuildContext context, List<Map<String, dynamic>> employees) {
  final bloc = context.read<DocRegistryBloc>();
  showDialog(
    context: context,
    builder: (dialogCtx) => IssueLetterDialog(
      employees: employees,
      onSave: (payload) => bloc.add(SubmitIssueLetterEvent(payload)),
    ),
  );
}

class IssueLetterDialog extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final Function(Map<String, dynamic>) onSave;

  const IssueLetterDialog({super.key, required this.employees, required this.onSave});

  @override
  State<IssueLetterDialog> createState() => _IssueLetterDialogState();
}

class _IssueLetterDialogState extends State<IssueLetterDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedEmpId;
  String _docType = "APPOINTMENT_LETTER";
  DateTime _issueDate = DateTime.now();
  final TextEditingController _customBodyCtrl = TextEditingController();
  String _conductRating = "Good and Professional";

  @override
  void initState() {
    super.initState();
    _selectedEmpId = widget.employees.first['id'].toString();
  }

  @override
  void dispose() {
    _customBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(width: 3.5, height: 18, color: kBrandBlue),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Issue Official Employment Document", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kDarkSlate)),
              Text("Generates letterhead snapshot with Company Profile branding & Signatures", style: TextStyle(fontSize: 9.5, color: kTextMuted)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedEmpId,
                  decoration: _inputDeco("TARGET EMPLOYEE *"),
                  items: widget.employees.map((e) {
                    return DropdownMenuItem(
                      value: e['id'].toString(),
                      child: Text("${e['first_name']} ${e['last_name']} (${e['emp_code']}) • ${e['designation_title'] ?? 'Staff'}", style: const TextStyle(fontSize: 11.5)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedEmpId = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _docType,
                  decoration: _inputDeco("LETTER / CERTIFICATE TYPE *"),
                  items: kDocTypeMap.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 11.5)));
                  }).toList(),
                  onChanged: (v) => setState(() => _docType = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _issueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => _issueDate = d);
                        },
                        child: InputDecorator(
                          decoration: _inputDeco("DATE OF ISSUANCE *"),
                          child: Text(DateFormat('yyyy-MM-dd').format(_issueDate), style: const TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ),
                    if (_docType == "EXPERIENCE_LETTER" || _docType == "RELIEVING_LETTER") ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _conductRating,
                          decoration: _inputDeco("CONDUCT RATING"),
                          items: ["Excellent and Exemplary", "Good and Professional", "Satisfactory"]
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (v) => setState(() => _conductRating = v!),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customBodyCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 11.5),
                  decoration: _inputDeco("CUSTOM CLAUSES / OVERRIDE BODY (OPTIONAL)"),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              "employee_id": _selectedEmpId,
              "document_type": _docType,
              "issue_date": DateFormat('yyyy-MM-dd').format(_issueDate),
              "custom_letter_body": _customBodyCtrl.text.trim(),
              "conduct_rating": _conductRating,
            });
            Navigator.pop(context);
          },
          child: const Text("ISSUE & GENERATE PDF"),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
    filled: true,
    fillColor: kCardBg,
  );
}

// =============================================================================
// 5. MODAL: VIEW LETTER DETAILS & VERIFICATION TOKEN
// =============================================================================
void showLetterPreviewModal(BuildContext context, EmploymentDocItem doc) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(width: 3.5, height: 18, color: kBrandBlue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.documentNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDarkSlate)),
              Text("${doc.documentTypeDisplay} • ${doc.employeeName} (${doc.employeeCode})", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoSec("DOCUMENT VERIFICATION SNAPSHOT"),
              _infoRow("Issuing Entity", doc.companyName),
              _infoRow("Date of Issuance", doc.issueDate),
              _infoRow("Designation Snapshot", doc.designationSnapshot),
              _infoRow("Joining Date Snapshot", doc.joiningDateSnapshot),
              if (doc.relievingDateSnapshot != null) _infoRow("Relieving Date Snapshot", doc.relievingDateSnapshot!),
              _infoRow("Compensation (CTC)", NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(doc.ctcSnapshot)),
              _infoRow("Conduct Rating", doc.conductRating ?? 'Good and Professional'),
              const Divider(height: 16),
              _infoSec("SECURITY & VERIFICATION TOKEN"),
              _infoRow("Token UUID", doc.verificationToken),
              _infoRow("Status", doc.status),
              const Divider(height: 16),
              if (doc.customLetterBody != null && doc.customLetterBody!.isNotEmpty) ...[
                _infoSec("CUSTOM CLAUSES BODY"),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(doc.customLetterBody!, style: const TextStyle(fontSize: 10.5, color: kDarkSlate)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (doc.generatedPdf != null && doc.generatedPdf!.isNotEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () => launchUrl(Uri.parse(doc.generatedPdf!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.download_rounded, size: 14),
            label: const Text("DOWNLOAD PDF"),
          ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
      ],
    ),
  );
}

Widget _infoSec(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandBlue, letterSpacing: 0.5)),
);

Widget _infoRow(String l, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2.5),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(fontSize: 10.5, color: kTextMuted)),
      Text(v, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
    ],
  ),
);
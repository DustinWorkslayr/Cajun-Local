import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_subscriptions_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/menu_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/deals_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';
import 'package:cajun_local/features/events/data/repositories/business_events_repository.dart';
import 'package:cajun_local/features/businesses/data/models/menu_section.dart';
import 'package:cajun_local/features/deals/data/models/deal.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:cajun_local/features/events/data/models/business_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'listing_edit_controller.g.dart';

class ListingEditState {
  ListingEditState({
    required this.listing,
    required this.menuSections,
    required this.deals,
    required this.punchCards,
    required this.events,
    required this.businessTier,
  });

  final Business? listing;
  final List<MenuSection> menuSections; 
  final List<Deal> deals;
  final List<PunchCardProgram> punchCards;
  final List<BusinessEvent> events;
  final String? businessTier;
}

@riverpod
class ListingEditController extends _$ListingEditController {
  @override
  FutureOr<ListingEditState> build(String listingId) async {
    return _fetchData(listingId);
  }

  Future<ListingEditState> _fetchData(String listingId) async {
    final results = await Future.wait<dynamic>([
      BusinessRepository().getByIdForManager(listingId),
      MenuRepository().getSectionsForBusiness(listingId), // Placeholder for real data
      DealsRepository().listForBusiness(listingId),
      PunchCardProgramsRepository().listActive(businessId: listingId),
      BusinessEventsRepository().listForBusiness(listingId),
    ]);

    final tier = await BusinessSubscriptionsRepository().getActivePlanTierForBusiness(listingId);

    return ListingEditState(
      listing: results[0] as Business?,
      menuSections: results[1] as List<MenuSection>,
      deals: results[2] as List<Deal>,
      punchCards: results[3] as List<PunchCardProgram>,
      events: results[4] as List<BusinessEvent>,
      businessTier: tier,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData(listingId));
  }
}

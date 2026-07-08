import 'customer_water_meter_request.dart';

/// One page of the signed-in customer's water meter requests
/// (`PageResult<WaterMeterRequestResponse>`), used for the server-side
/// paginated / infinite-scroll list in `CustomerRequestsScreen`.
class CustomerWaterMeterRequestPage {
  const CustomerWaterMeterRequestPage({
    required this.items,
    required this.totalCount,
  });

  final List<CustomerWaterMeterRequest> items;
  final int totalCount;
}

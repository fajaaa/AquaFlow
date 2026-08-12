import 'customer_water_meter.dart';

/// One page of the signed-in customer's water meters (`PageResult<WaterMeterResponse>`),
/// used for the server-side paginated water meter list.
class CustomerWaterMeterPage {
  const CustomerWaterMeterPage({required this.items, required this.totalCount});

  final List<CustomerWaterMeter> items;
  final int totalCount;
}

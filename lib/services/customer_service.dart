import '../models/customer.dart';
import 'database_helper.dart';

class CustomerService {
  static Future<List<Customer>> getCustomers() async {
    return await DatabaseHelper.instance.getAllCustomers();
  }
}

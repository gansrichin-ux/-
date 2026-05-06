import '../../models/cargo_model.dart';
import '../../models/user_model.dart';
import '../config/cargo_statuses.dart';
import '../../repositories/cargo_repository.dart';
import '../../repositories/site_workflow_repository.dart';

class CargoWorkflowService {
  CargoWorkflowService._();
  static final instance = CargoWorkflowService._();

  Future<void> publishCargo(CargoModel cargo) async {
    final newCargo = cargo.copyWith(status: CargoStatus.published);
    await CargoRepository.instance.addCargo(newCargo);
  }

  Future<void> assignDriver({
    required CargoModel cargo,
    required UserModel driver,
    required UserModel actor,
  }) async {
    await CargoRepository.instance.assignDriver(
      cargoId: cargo.id,
      driverId: driver.uid,
      driverName: driver.displayName,
    );
    
    await SiteWorkflowRepository.instance.updateCargoStatus(
      cargo: cargo.copyWith(
        driverId: driver.uid,
        driverName: driver.displayName,
      ),
      actor: actor,
      status: CargoStatus.executorSelected,
    );
  }

  Future<void> updateStatus({
    required CargoModel cargo,
    required String newStatus,
    required UserModel actor,
  }) async {
    await SiteWorkflowRepository.instance.updateCargoStatus(
      cargo: cargo,
      actor: actor,
      status: newStatus,
    );
  }

  Future<void> cancelCargo({
    required CargoModel cargo,
    required UserModel actor,
  }) async {
    await updateStatus(
      cargo: cargo,
      newStatus: CargoStatus.cancelled,
      actor: actor,
    );
  }
}

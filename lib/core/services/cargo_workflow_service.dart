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

  /// Assigns a carrier (перевозчик) to a cargo.
  /// Writes both legacy `driverId` and new `executorId` fields for compatibility.
  Future<void> assignCarrier({
    required CargoModel cargo,
    required UserModel carrier,
    required UserModel actor,
  }) async {
    await CargoRepository.instance.assignCarrier(
      cargoId: cargo.id,
      carrierId: carrier.uid,
      carrierName: carrier.displayName,
    );

    await SiteWorkflowRepository.instance.updateCargoStatus(
      cargo: cargo.copyWith(
        executorId: carrier.uid,
        executorName: carrier.displayName,
      ),
      actor: actor,
      status: CargoStatus.executorSelected,
    );
  }

  /// Legacy alias — mobile screens that already call assignDriver keep working.
  Future<void> assignDriver({
    required CargoModel cargo,
    required UserModel driver,
    required UserModel actor,
  }) =>
      assignCarrier(cargo: cargo, carrier: driver, actor: actor);

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

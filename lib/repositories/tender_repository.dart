import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tender_model.dart';
import '../models/user_model.dart';

class TenderRepository {
  TenderRepository._();
  static final TenderRepository instance = TenderRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _tenders => _db.collection('tenders');

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<List<TenderModel>> watchAllTenders() {
    return _tenders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TenderModel.fromFirestore).toList());
  }

  Stream<List<TenderBidModel>> watchBidsForTender(String tenderId) {
    return _tenders
        .doc(tenderId)
        .collection('bids')
        .orderBy('price')
        .snapshots()
        .map((s) => s.docs.map(TenderBidModel.fromFirestore).toList());
  }

  Stream<TenderBidModel?> watchMyBid(String tenderId, String uid) {
    return _tenders
        .doc(tenderId)
        .collection('bids')
        .where('bidderId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((s) =>
            s.docs.isEmpty ? null : TenderBidModel.fromFirestore(s.docs.first));
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<TenderModel> createTender({
    required String title,
    required String description,
    required String from,
    required String to,
    required double startingPrice,
    required String currency,
    required DateTime deadlineAt,
    required UserModel owner,
    double? weightKg,
    double? volumeM3,
  }) async {
    final ref = _tenders.doc();
    final tender = TenderModel(
      id: ref.id,
      title: title,
      description: description,
      from: from,
      to: to,
      startingPrice: startingPrice,
      currency: currency,
      ownerId: owner.uid,
      ownerName: owner.displayName,
      deadlineAt: deadlineAt,
      createdAt: DateTime.now(),
      weightKg: weightKg,
      volumeM3: volumeM3,
    );
    await ref.set(tender.toMap());
    return tender;
  }

  // ─── Bid ──────────────────────────────────────────────────────────────────

  Future<void> placeBid({
    required TenderModel tender,
    required UserModel bidder,
    required double price,
    required String note,
  }) async {
    // Check if bidder already has a bid
    final existing = await _tenders
        .doc(tender.id)
        .collection('bids')
        .where('bidderId', isEqualTo: bidder.uid)
        .get();

    final bid = TenderBidModel(
      id: existing.docs.isEmpty ? _tenders.doc().id : existing.docs.first.id,
      tenderId: tender.id,
      bidderId: bidder.uid,
      bidderName: bidder.displayName,
      bidderUsername: bidder.displayUsername,
      price: price,
      note: note,
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      final tenderRef = _tenders.doc(tender.id);
      final bidRef = tenderRef.collection('bids').doc(bid.id);

      tx.set(bidRef, bid.toMap());

      if (existing.docs.isEmpty) {
        tx.update(tenderRef, {'bidCount': FieldValue.increment(1)});
      }
    });
  }

  // ─── Accept bid / close tender ────────────────────────────────────────────

  Future<void> acceptBid({
    required TenderModel tender,
    required TenderBidModel bid,
  }) async {
    await _db.runTransaction((tx) async {
      final tenderRef = _tenders.doc(tender.id);

      // Mark tender as awarded
      tx.update(tenderRef, {
        'status': tenderStatusAwarded,
        'winnerId': bid.bidderId,
        'winnerName': bid.bidderName,
        'winnerPrice': bid.price,
      });

      // Mark winning bid
      tx.update(
        tenderRef.collection('bids').doc(bid.id),
        {'status': bidStatusAccepted},
      );

      // Reject all other bids
      // Note: this is best-effort; the stream will show the rest as pending
      // until a cloud function or next batch handles them
    });

    // Reject other bids (outside transaction for simplicity)
    final allBids =
        await _tenders.doc(tender.id).collection('bids').get();
    final batch = _db.batch();
    for (final doc in allBids.docs) {
      if (doc.id != bid.id) {
        batch.update(doc.reference, {'status': bidStatusRejected});
      }
    }
    await batch.commit();
  }

  Future<void> closeTender(String tenderId) async {
    await _tenders.doc(tenderId).update({'status': tenderStatusClosed});
  }

  Future<void> deleteTender(String tenderId) async {
    await _tenders.doc(tenderId).delete();
  }
}

/// Post Office savings service charges (India Post website). GST is extra.
enum ServiceFee {
  duplicatePassbook,
  statement,
  lostCertificate,
  nomination,
  transfer,
  pledge,
  chequeBook,
  chequeDishonour,
}

/// Fee in rupees (cheque book: per leaf after the free leaves).
const kServiceFees = {
  ServiceFee.duplicatePassbook: 50,
  ServiceFee.statement: 20,
  ServiceFee.lostCertificate: 10,
  ServiceFee.nomination: 50,
  ServiceFee.transfer: 100,
  ServiceFee.pledge: 100,
  ServiceFee.chequeBook: 2,
  ServiceFee.chequeDishonour: 100,
};

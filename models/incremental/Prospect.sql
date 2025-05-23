MODEL (
  name sqlmesh_tpcdi.prospect,
  kind FULL,
);

SELECT 
  agencyid,
  recdate.sk_dateid sk_recorddateid,
  origdate.sk_dateid sk_updatedateid,
  p.batchid,
  nvl2(c.customerid, True, False) iscustomer, 
  p.lastname,
  p.firstname,
  p.middleinitial,
  p.gender,
  p.addressline1,
  p.addressline2,
  p.postalcode,
  city,
  state,
  country,
  phone,
  income,
  numbercars,
  numberchildren,
  maritalstatus,
  age,
  creditrating,
  ownorrentflag,
  employer,
  numbercreditcards,
  networth,
  iff(
      iff(networth > 1000000 or income > 200000, 'HighValue+','') || 
      iff(numberchildren > 3 or numbercreditcards > 5,'Expenses+','') ||
      iff(age > 45, 'Boomer+', '') ||
      iff(income < 50000 or creditrating < 600 or networth < 100000, 'MoneyAlert+','') ||
      iff(numbercars > 3 or numbercreditcards > 7, 'Spender+','') ||
      iff(age < 25 and networth > 1000000, 'Inherited+','') IS NOT NULL,
    left(
      iff(networth > 1000000 or income > 200000,'HighValue+','') || 
      iff(numberchildren > 3 or numbercreditcards > 5,'Expenses+','') ||
      iff(age > 45, 'Boomer+', '') ||
      iff(income < 50000 or creditrating < 600 or networth < 100000, 'MoneyAlert+','') ||
      iff(numbercars > 3 or numbercreditcards > 7, 'Spender+','') ||
      iff(age < 25 and networth > 1000000, 'Inherited+',''),
      length(
        iff(networth > 1000000 or income > 200000,'HighValue+','') || 
        iff(numberchildren > 3 or numbercreditcards > 5,'Expenses+','') ||
        iff(age > 45, 'Boomer+', '') ||
        iff(income < 50000 or creditrating < 600 or networth < 100000, 'MoneyAlert+','') ||
        iff(numbercars > 3 or numbercreditcards > 7, 'Spender+','') ||
        iff(age < 25 and networth > 1000000, 'Inherited+',''))
      -1),
    NULL) marketingnameplate
FROM (
  SELECT 
    * FROM (
    SELECT
      agencyid,
      max(batchid) recordbatchid,
      lastname,
      firstname,
      middleinitial,
      gender,
      addressline1,
      addressline2,
      postalcode,
      city,
      state,
      country,
      phone,
      income,
      numbercars,
      numberchildren,
      maritalstatus,
      age,
      creditrating,
      ownorrentflag,
      employer,
      numbercreditcards,
      networth,
      min(batchid) batchid
    FROM sqlmesh_tpcdi.prospectraw p
    GROUP BY
      agencyid,
      lastname,
      firstname,
      middleinitial,
      gender,
      addressline1,
      addressline2,
      postalcode,
      city,
      state,
      country,
      phone,
      income,
      numbercars,
      numberchildren,
      maritalstatus,
      age,
      creditrating,
      ownorrentflag,
      employer,
      numbercreditcards,
      networth)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY agencyid ORDER BY batchid DESC) = 1) p
JOIN (
  SELECT 
    sk_dateid,
    batchid
  FROM sqlmesh_tpcdi.batchdate b 
  JOIN sqlmesh_tpcdi.dimdate d 
    ON b.batchdate = d.datevalue) recdate
  ON p.recordbatchid = recdate.batchid
JOIN (
  SELECT 
    sk_dateid,
    batchid
  FROM sqlmesh_tpcdi.batchdate b 
  JOIN sqlmesh_tpcdi.dimdate d 
    ON b.batchdate = d.datevalue) origdate
  ON p.batchid = origdate.batchid
LEFT JOIN (
  SELECT 
    customerid,
    lastname,
    firstname,
    addressline1,
    addressline2,
    postalcode
  FROM sqlmesh_tpcdi.dimcustomerstg
  WHERE iscurrent) c
  ON 
    upper(p.LastName) = upper(c.lastname)
    and upper(p.FirstName) = upper(c.firstname)
    and upper(p.AddressLine1) = upper(c.addressline1)
    and upper(nvl(p.addressline2, '')) = upper(nvl(c.addressline2, ''))
    and upper(p.PostalCode) = upper(c.postalcode)
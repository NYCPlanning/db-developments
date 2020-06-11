/*
DESCRIPTION: 
    create lookup tables for occ codes, status codes
    
OUTPUTS:
    occ_lookup (
        dob_occ text,
        occ text
    )

    status_lookup (
        dob_status text,
        status text
    )
*/
DROP TABLE IF EXISTS occ_lookup;
CREATE TABLE occ_lookup(
    dob_occ text,
    occ text
); 

INSERT INTO occ_lookup(dob_occ, occ)
VALUES
('.RES', 'Residential: Not Specified (.RES)'),
('A', 'Industrial: High Hazard (A)'),
('A-1', 'Assembly: Theaters, Churches (A-1)'),
('A-2', 'Assembly: Eating & Drinking (A-2)'),
('A-3', 'Assembly: Other (A-3)'),
('A-4', 'Assembly: Indoor Sports (A-4)'),
('A-5', 'Assembly: Outdoors (A-5)'),
('B', 'Commercial: Offices (B)'),
('B-1', 'Storage: Moderate Hazard (B-1)'),
('B-2', 'Storage: Low Hazard (B-2)'),
('C', 'Commercial: Retail (C)'),
('COM', 'Commercial: Not Specified (COM)'),
('D-1', 'Industrial: Moderate Hazard (D-1)'),
('D-2', 'Industrial: Low Hazard (D-2)'),
('E', 'Unknown (E)'),
('F-1', 'Industrial: Moderate Hazard (F-1)'),
('F-1A', 'Assembly: Theaters, Churches (F-1A)'),
('F-1B', 'Assembly: Theaters, Churches (F-1B)'),
('F-2', 'Unknown (F-2)'),
('F-3', 'Assembly: Museums (F-3)'),
('F-4', 'Assembly: Eating & Drinking (F-4)'),
('G', 'Educational (G)'),
('H-1', 'Unknown (H-1)'),
('H-2', 'Unknown (H-2)'),
('H-3', 'Industrial: High Hazard (H-3)'),
('H-4', 'Industrial: High Hazard (H-4)'),
('H-5', 'Industrial: High Hazard (H-5)'),
('I-1', 'Institutional: Assisted Living (I-1)'),
('I-2', 'Institutional: Incapacitated (I-2)'),
('I-3', 'Institutional: Restrained (I-3)'),
('I-4', 'Institutional: Day Care (I-4)'),
('J-0', 'Residential: 3 or More Units (J-0)'),
('J-1', 'Residential: Hotels, Dormitories (J-1)'),
('J-2', 'Residential: 3 or More Units (J-2)'),
('J-3', 'Residential: 1-2 Family Houses (J-3)'),
('K', 'Miscellaneous (K)'),
('M', 'Commercial: Retail (M)'),
('NC', 'Residential: 3 or More Units (NC)'),
('PUB', 'Assembly: Other (PUB)'),
('R-1', 'Residential: Hotels, Dormitories (R-1)'),
('R-2', 'Residential: 3 or More Units (R-2)'),
('R-3', 'Residential: 1-2 Family Houses (R-3)'),
('RES', 'Residential: Not Specified (RES)'),
('S-1', 'Storage: Moderate Hazard (S-1)'),
('S-2', 'Storage: Low Hazard (S-2)'),
('U', 'Miscellaneous (U)');

DROP TABLE IF EXISTS status_lookup;
CREATE TABLE status_lookup(
    dob_status text,
    status text
); 

INSERT INTO status_lookup(dob_status, status)
VALUES
('A', '1. Filed'),
('A/P ENTIRE', '1. Filed'),
('AP-NPE', '1. Filed'),
('APPLICATION ASSIGNED TO PLAN EXAMINER', '1. Filed'),
('APPLICATION PROCESSED - ENTIRE', '1. Filed'),
('APPLICATION PROCESSED - NO PLAN EXAM', '1. Filed'),
('APPLICATION PROCESSED-PART-NO PAYMENT', '1. Filed'),
('APPLICATION PROCESSED - PAYMENT ONLY', '1. Filed'),
('A/P TO D.E.A.R', '1. Filed'),
('A/P UNPAID', '1. Filed'),
('ASSIGNED TO P/E', '1. Filed'),
('B', '1. Filed'),
('C', '1. Filed'),
('D', '1. Filed'),
('E', '1. Filed'),
('F', '1. Filed'),
('G', '1. Filed'),
('PRE-FILED', '1. Filed'),
('PRE-FILING', '1. Filed'),
('APPROVED', '2. Plan Examination'),
('H', '2. Plan Examination'),
('J', '2. Plan Examination'),
('K', '2. Plan Examination'),
('P', '2. Plan Examination'),
('P/E DISAPPROVED', '2. Plan Examination'),
('P/E IN PROCESS', '2. Plan Examination'),
('P/E PARTIAL APRV', '2. Plan Examination'),
('PLAN EXAM - APPROVED', '2. Plan Examination'),
('PLAN EXAM - DISAPPROVED', '2. Plan Examination'),
('PLAN EXAM - IN PROCESS', '2. Plan Examination'),
('PLAN EXAM - PARTIAL APPROVAL', '2. Plan Examination'),
('PERMITE-ENTIRE', '3. Permitted'),
('PERMIT ISSUED - ENTIRE JOB/WORK', '3. Permitted'),
('PERMIT ISSUED - PARTIAL JOB', '3. Permitted'),
('PERMIT-PARTIAL', '3. Permitted'),
('Q', '3. Permitted'),
('R', '3. Permitted'),
('SIGNED OFF', '5. Complete'),
('U', '5. Complete'),
('X', '5. Complete'),
('3', '9. Withdrawn'),
('SUSPENDED', '9. Withdrawn');
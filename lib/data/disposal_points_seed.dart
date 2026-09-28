import '../models/disposal_point.dart';

// Category names must match WasteCategory.name exactly:
// "Electronics", "Batteries", "Plastic", "Clothing"
final List<DisposalPoint> disposalPoints = [
  // ---------- e-Kunu (Electronics + small batteries) ----------
  DisposalPoint(
    name: "e-Kunu - WTC",
    address: "Level 3, Echelon Square, World Trade Centre, Colombo 01",
    latitude: 6.932854401,
    longitude: 79.84415973,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - Modern",
    address: "No: 528, Alfred House Avenue, R A De Mel Mawatha, Colombo 03",
    latitude: 6.918765532,
    longitude: 79.8626834,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - Dialog Finance Building",
    address: "Level 01 No.57, Srimath Anagarika Dharmapala Mawatha, Colombo 03",
    latitude: 6.898872303, // TODO: double-check this pin (looks too far south)
    longitude: 79.85620338,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - One Galle Face",
    address: "Shop No 43 & 44, Level 5, No.1A, Center Road, Galle Face, Colombo 02",
    latitude: 6.928311988,
    longitude: 79.84533571,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - Bambalapitiya SC",
    address: "No 28/A, Hildon Place, Duplication Road, Colombo 04",
    latitude: 6.886719373,
    longitude: 79.86019663,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - Nawala",
    address: "No: 275, Nawala Road, Nawala",
    latitude: 6.886517607,
    longitude: 79.88672055,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - Nugegoda SC",
    address: "No: 84, Stanley Thilakarathne Mawatha, Nugegoda",
    latitude: 6.875694875,
    longitude: 79.89739579,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),
  DisposalPoint(
    name: "e-Kunu - Negombo",
    address: "No: 365, Main Street, Negombo",
    latitude: 7.21385793,
    longitude: 79.84462333,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "ekunu.lk",
  ),

  // ---------- Other electronics / battery recyclers ----------
  DisposalPoint(
    name: "Neptune Recyclers (Pvt) Ltd",
    address: "No. 230/6, Sedawatta Road, Sedawatta, Wellampitiya",
    latitude: 6.9535,
    longitude: 79.8892,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "Eco Friends",
    address: "Sedawatta - Ambatale Rd, Wellampitiya, Peliyagoda",
    latitude: 6.9479,
    longitude: 79.8973,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "Evergreen Trading and Marketing",
    address: "No. 45, Muthuraja Mawatha, Mabola, Wattala",
    latitude: 6.99587503,
    longitude: 79.89471143,
    categoriesAccepted: ["Electronics", "Batteries"],
    source: "Google Maps",
  ),

  // ---------- Plastic ----------
  DisposalPoint(
    name: "Zerotrash Recyclable Plastic Collection Centre",
    address: "Boralesgamuwa", // TODO: add street address
    latitude: 6.848785911,
    longitude: 79.90444943,
    categoriesAccepted: ["Plastic"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "Kaduwela Plastic Recycling Center",
    address: "567/3, Yashodara Mawatha, Dedigamuwa",
    latitude: 6.892521223,
    longitude: 80.02355631,
    categoriesAccepted: ["Plastic"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "Cargills Food City",
    address: "No. 45, Bauddhaloka Mawatha, Gampaha",
    latitude: 7.0864,
    longitude: 79.9961,
    categoriesAccepted: ["Plastic"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "Saubagya Plastic",
    address: "438 A, Kudabolaththa, Ganemulla",
    latitude: 7.51934865, // TODO: re-copy pin, this is far north of Ganemulla
    longitude: 79.96906872,
    categoriesAccepted: ["Plastic"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "Nimal Plastic",
    address: "127, Elpitiya Mawatha, Ragama",
    latitude: 7.061380399,
    longitude: 79.90473585,
    categoriesAccepted: ["Plastic"],
    source: "Google Maps",
  ),

  // ---------- Clothing ----------
  DisposalPoint(
    name: "GreenKeepers (Pvt) Ltd",
    address: "115, 6 Rosmead Pl, Colombo",
    latitude: 6.9205,
    longitude: 79.8661,
    categoriesAccepted: ["Clothing"],
    source: "Google Maps",
  ),
  DisposalPoint(
    name: "The Salvation Army",
    address: "Union Place, Colombo",
    latitude: 6.9248,
    longitude: 79.8569,
    categoriesAccepted: ["Clothing"],
    source: "Google Maps",
  ),
];
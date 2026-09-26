import '../models/waste_category.dart';

final List<WasteCategory> wasteCategories = [
  WasteCategory(
    name: "Electronics",
    icon: "📱",
    disposalType: "Special disposal required",
    guidanceText:
        "Electronics contain metals and components that are valuable to recover but harmful if they end up in a landfill. Never throw phones, chargers, laptops, or small appliances in normal waste — take them to a dedicated e-waste collection point instead. Many places will even give you a small credit or accept trade-ins.",
    warningText:
        "Contains materials that can leak into soil and water if landfilled. Never burn or incinerate.",
  ),
  WasteCategory(
    name: "Batteries",
    icon: "🔋",
    disposalType: "Hazardous waste",
    guidanceText:
        "Even 'dead' batteries still contain hazardous material — collect them in a small container at home and drop them off in a batch rather than one at a time. Most electronics or hardware stores have a battery drop-off box.",
    warningText:
        "Batteries can leak corrosive chemicals or, in the case of lithium batteries, catch fire if crushed or punctured. Keep them separate from all other trash.",
  ),
  WasteCategory(
    name: "Plastic",
    icon: "🥤",
    disposalType: "Recyclable",
    guidanceText:
        "Most rigid plastics (bottles, containers, packaging) can be recycled — rinse out any food or liquid residue first so the batch isn't contaminated. Soft/flexible plastics (bags, wrappers) usually need a separate collection point since standard recycling centres often can't process them.",
    warningText:
        "Contaminated or greasy plastic can get an entire batch rejected at the recycling centre.",
  ),
  WasteCategory(
    name: "Clothing",
    icon: "👕",
    disposalType: "Donate / Recycle",
    guidanceText:
        "If clothing is still wearable, donation should always come before disposal — someone else can get real use out of it. If it's too worn, stained, or damaged to donate, many donation centres and some retailers still accept it for textile recycling rather than landfill.",
    warningText: null,
  ),
];
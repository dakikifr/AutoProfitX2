--list of items that classes cannot use
local BI = LibStub("LibBabble-Inventory-3.0"):GetLookupTable()

AutoProfitX2_Proficiencies = {
	["DRUID"] = {
		[ARMOR] = {
			[BI["Mail"]] = true,
			[BI["Shields"]] = true,
			[BI["Plate"]] = true,
			[BI["Librams"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["One-Handed Axes"]] = true,
			[BI["One-Handed Swords"]] = true,
			[BI["Two-Handed Axes"]] = true,
			[BI["Two-Handed Swords"]] = true,
			[BI["Wands"]] = true,
			noOffhand = true
		}
	},
	["HUNTER"] = {
		[ARMOR] = {
			[BI["Shields"]] = true,
			[BI["Plate"]] = true,
			[BI["Relic"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["One-Handed Maces"]] = true,
			[BI["Two-Handed Maces"]] = true,
			[BI["Wands"]] = true,
		}
	},
	["MAGE"] = {
		[ARMOR] = {
			[BI["Leather"]] = true,
			[BI["Mail"]] = true,
			[BI["Shields"]] = true,
			[BI["Plate"]] = true,
			[BI["Relic"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["Fist Weapons"]] = true,
			[BI["One-Handed Axes"]] = true,
			[BI["One-Handed Maces"]] = true,
			[BI["Polearms"]] = true,
			[BI["Two-Handed Axes"]] = true,
			[BI["Two-Handed Maces"]] = true,
			[BI["Two-Handed Swords"]] = true,
			noOffhand = true
		}
	},
	["PALADIN"] = {
		[ARMOR] = {
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["Daggers"]] = true,
			[BI["Fist Weapons"]] = true,
			[BI["Staves"]] = true,
			[BI["Wands"]] = true,
			noOffhand = true
		}
	},
	["PRIEST"] = {
		[ARMOR] = {
			[BI["Leather"]] = true,
			[BI["Mail"]] = true,
			[BI["Shields"]] = true,
			[BI["Plate"]] = true,
			[BI["Relic"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["Fist Weapons"]] = true,
			[BI["One-Handed Axes"]] = true,
			[BI["One-Handed Swords"]] = true,
			[BI["Polearms"]] = true,
			[BI["Two-Handed Axes"]] = true,
			[BI["Two-Handed Maces"]] = true,
			[BI["Two-Handed Swords"]] = true,
			noOffhand = true
		}
	},
	["ROGUE"] = {
		[ARMOR] = {
			[BI["Mail"]] = true,
			[BI["Shields"]] = true,
			[BI["Plate"]] = true,
			[BI["Relic"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Polearms"]] = true,
			[BI["Staves"]] = true,
			[BI["Two-Handed Axes"]] = true,
			[BI["Two-Handed Maces"]] = true,
			[BI["Two-Handed Swords"]] = true,
			[BI["Wands"]] = true,
		}
	},
	["SHAMAN"] = {
		[ARMOR] = {
			[BI["Plate"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["One-Handed Swords"]] = true,
			[BI["Polearms"]] = true,
			[BI["Two-Handed Swords"]] = true,
			[BI["Wands"]] = true,
		}
	},
	["WARLOCK"] = {
		[ARMOR] = {
			[BI["Leather"]] = true,
			[BI["Mail"]] = true,
			[BI["Shields"]] = true,
			[BI["Plate"]] = true,
			[BI["Relic"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["Fist Weapons"]] = true,
			[BI["One-Handed Axes"]] = true,
			[BI["One-Handed Maces"]] = true,
			[BI["Polearms"]] = true,
			[BI["Two-Handed Axes"]] = true,
			[BI["Two-Handed Maces"]] = true,
			[BI["Two-Handed Swords"]] = true,
			noOffhand = true
		}
	},
	["WARRIOR"] = {
		[ARMOR] = {
			[BI["Relic"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Wands"]] = true,
		}
	},
	["DEATHKNIGHT"] = {
		[ARMOR] = {
			[BI["Shields"]] = true,
		},
		[ENCHSLOT_WEAPON] = {
			[BI["Bows"]] = true,
			[BI["Crossbows"]] = true,
			[BI["Guns"]] = true,
			[BI["Thrown"]] = true,
			[BI["Daggers"]] = true,
			[BI["Fist Weapons"]] = true,
			[BI["Staves"]] = true,
			[BI["Wands"]] = true,
		}
	}
}

AutoProfitX2_InfArmorProficiencies_Sub40 = {
	["DRUID"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
		},
	},
	["ROGUE"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
		},
	},
	["HUNTER"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
		},
	},
	["SHAMAN"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
		},
	},
	["PALADIN"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
		},
	},
	["WARRIOR"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
		},
	},
	["DEATHKNIGHT"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
		},
	}
}

AutoProfitX2_InfArmorProficiencies_Over40 = {
	["DRUID"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
		},
	},
	["ROGUE"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
		},
	},
	["HUNTER"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
		},
	},
	["SHAMAN"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
		},
	},
	["PALADIN"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
			[BI["Mail"]] = true,
		},
	},
	["WARRIOR"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
			[BI["Mail"]] = true,
		},
	},
	["DEATHKNIGHT"] = {
		[ARMOR] = {
			[BI["Cloth"]] = true,
			[BI["Leather"]] = true,
			[BI["Mail"]] = true,
		},
	}
}

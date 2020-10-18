local L = LibStub("AceLocale-3.0"):NewLocale("AutoProfitX2","enUS",true)

if L then
  L["/apx"] = true
  L["options"] = true
  L["Show options panel."] = true
  L["add"] = true
  L["Add items to global ignore list."] = true
  L["<item link>[<item link>...]"] = true
  L["rem"] = true
  L["Remove items from global ignore list."] = true
  L["me"] = true
  L["Add or remove an item from your exception list."] = true
  L["list"] = true
  L["List your exceptions."] = true

  --options
  L["Addon Options"] = "Options"
  L["Auto Sell"] = true
  L["Automatically sell junk items when opening vendor window."] = true
  L["Sales Reports"] = true
  L["Print items being sold in chat frame."] = true
  L["Show Profit"] = true
  L["Print total profit after sale."] = true
  L["Sell Soulbound"] = true
  L["Sell unusable soulbound items."] = true
  L["Sell non-optimal Armor"] = true
  L["Sell non-optimal soulbound armor."] = true
  L["Button Animation Options"] = true
  L["Set up when you want the treasure pile in the button to spin."] = true
  L["Never spin"] = true
  L["Mouse-over and profit"] = true
  L["Mouse-over"] = true
  L["Profits"] = true
  L["Spin when you mouse-over the button and there is junk to vendor."] = true
  L["Spin every time you mouse over."] = true
  L["Spin every time there is junk to sell."] = true
  L["Reset Button Pos"] = true
  L["Reset APX button position on the vendor screen to the top right corner."] = true
  L["Exception List"] = true
  L["Clear Exceptions"] = true
  L["Remove all items from exception list."] = true
  L["Import Exception List"] = true
  L["Choose character to import exceptions from. Your exceptions will be deleted."] = true

  --functions
  L["Added LINK to exception list for all characters."] = function(link) return "Added "..link.." to exception list for all characters." end
  L["Invalid item link provided."] = true
  L["Removed LINK from all exception lists."] = function(link) return "Removed "..link.." from all exception lists." end
  L["Removed LINK from exception list."] = function(link) return "Removed "..link.." from exception list." end
  L["Added LINK to exception list."] = function(link) return "Added "..link.." to exception list." end
  L["Exceptions:"] = true
  L["Your exception list is empty."] = true
  L["Deleted all exceptions."] = true
  L["Exception list imported from NAME on REALM."] = function(name,realm) return "Exception list imported from "..name.." on "..realm.."." end
  L["Exception list could not be found for NAME on REALM."] = function(name,realm) return "Exception list could not be found for "..name.." on "..realm.."." end
  L["Sold LINK."] = function(link) return "Sold "..link.."." end
  L["Item LINK is junk, but cannot be sold."] = function(link) return "Item "..link.." is junk, but cannot be sold." end

  --button functions
  L["Total profits: PROFIT"] = function(profit) return "Total profits: "..profit end
  L["Sell Junk Items"] = true
  L["You have no junk items in your inventory."] = true

  --temporary features
  L["Update Exception List"] = true
  L["Update exception list from pre 2.0 AutoProfitX2 version."] = true
  L["Exceptions updated."] = true

  --FeatureFrame
  L["OneKey Sell"] = true
  L["OneKey sell junk items when opening vendor window"] = true

  --Price
  L["g "] = true
  L["s "] = true
  L["c"] = true

  --misc
  L["LIST_SEPARATOR"] = ", "		--separator used to separate words in a list for exmple ", " in rogue, mage, warrior. This is used to split classes listed in the tooltips under Class:
end

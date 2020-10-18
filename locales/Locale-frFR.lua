local L = LibStub("AceLocale-3.0"):NewLocale("AutoProfitX2","enUS",true)

if L then
  L["/apx"] = "/apx"
  L["options"] = "options"
  L["Show options panel."] = "Afficher le panneau d'options."
  L["add"] = "ajout"
  L["Add items to global ignore list."] = "Ajouter des objets à la liste d'ignore."
  L["<item link>[<item link>...]"] = "<lien de l'objet>[<lien de l'objet>...]"
  L["rem"] = "suppr"
  L["Remove items from global ignore list."] = "Enlever des objets de la liste d'ignore."
  L["me"] = "me"
  L["Add or remove an item from your exception list."] = "Ajouter ou supprimer des objets de votre liste d'exceptions."
  L["list"] = "liste"
  L["List your exceptions."] = "Liste de vos exceptions."

  --options
  L["Addon Options"] = "Options de l'addon"
  L["Auto Sell"] = "Vente automatique"
  L["Automatically sell junk items when opening vendor window."] = "Vendre automatiquement la camelote lorsqu'on ouvre la fenêtre du vendeur."
  L["Sales Reports"] = "Notifier les ventes"
  L["Print items being sold in chat frame."] = "Afficher les objets vendus dans la fenêtre de chat."
  L["Show Profit"] = "Afficher les profits"
  L["Print total profit after sale."] = "Afficher le total des profits après vente."
  L["Sell Soulbound"] = "Vendre les objets liés"
  L["Sell unusable soulbound items."] = "Vendre les objets liés inutilisables."
  --no longer used
  --L["Acquire Unsafe Links"] = "Obtenir les objets non fiables"
  --L["Automatically get information about unsafe item links. (CAUTION: may cause you to disconnect when displaying exception list!!!)"] = "Obtenir automatiquement les informations des objets invalides. (ATTENTION: risque de déconnexion lors de l'affichage de la liste d'exceptions !!!)"
  L["Button Animation Options"] = "Options d'animation du bouton"
  L["Set up when you want the treasure pile in the button to spin."] = "Paramétrage pour que le trésor du bouton tourne"
  L["Never spin"] = "Jamais tourner"
  L["Mouse-over and profit"] = "Survol de la souris et profits"
  L["Mouse-over"] = "Survol de la souris"
  L["Profits"] = "Profits"
  L["Spin when you mouse-over the button and there is junk to vendor."] = "Tourner lors du survol avec la souris ou qu'il y a des objets à vendre."
  L["Spin every time you mouse over."] = "Tourner lors du survol de la souris."
  L["Spin every time there is junk to sell."] = "Tourner dès qu'il y a des objets à vendre."
  L["Reset Button Pos"] = "RAZ la position du bouton"
  L["Reset APX button position on the vendor screen to the top right corner."] = "Réinitialise la position du bouton APX dans la fenêtre du vendeur dans le coin en haut à droite."
  L["Exception List"] = "Liste d'exceptions"
  L["Clear Exceptions"] = "Vider les exceptions"
  L["Remove all items from exception list."] = "Supprime tous les objets de la liste d'exceptions."
  L["Import Exception List"] = "Importer la liste d'exceptions"
  L["Choose character to import exceptions from. Your exceptions will be deleted."] = "Choisir un personnage pour importer sa liste d'exceptions. Les exceptions actuelles seront supprimées."

  --functions
  L["Added LINK to exception list for all characters."] = function(link) return "Ajout de "..link.." à la liste d'exceptions pour tous les personnages." end
  L["Invalid item link provided."] = "Le lien de l'objet fourni est invalide."
  L["Removed LINK from all exception lists."] = function(link) return "Suppression de "..link.." de toutes les listes d'exceptions." end
  L["Removed LINK from exception list."] = function(link) return "Suppression de "..link.." de la liste d'exceptions." end
  L["Added LINK to exception list."] = function(link) return "Ajout de "..link.." à la liste d'exceptions." end
  L["Exceptions:"] = "Exceptions :"
  L["Your exception list is empty."] = "La liste d'exception est vide."
  L["Deleted all exceptions."] = "Toutes les exceptions ont été supprimées."
  L["Exception list imported from NAME on REALM."] = function(name,realm) return "Liste d'exceptions importée de "..name.." de "..realm.."." end
  L["Exception list could not be found for NAME on REALM."] = function(name,realm) return "Liste d'exceptions introuvable pour "..name.." de "..realm.."." end
  L["Sold LINK."] = function(link) return link.." vendu." end
  L["Item LINK is junk, but cannot be sold."] = function(link) return "Objet "..link.." est une camelote, mais le vendeur n'en veut pas." end

  --button functions
  L["Total profits: PROFIT"] = function(profit) return "Profits totaux : "..profit end
  L["Sell Junk Items"] = "Vendre la camelote"
  L["You have no junk items in your inventory."] = "Pas de camelote dans l'inventaire."

  --temporary features
  L["Update Exception List"] = "MAJ la liste d'exceptions"
  L["Update exception list from pre 2.0 AutoProfitX2 version."] = "Mettre à jour la liste d'exceptions à partir d'une version d'AutoProfitX2 antérieure à la 2.0 ."
  L["Exceptions updated."] = "Liste d'exceptions mise à jour."

  --FeatureFrame
  L["OneKey Sell"] = "Raccourci de vente"
  L["OneKey sell junk items when opening vendor window"] = "Ce raccourci clavier vend la camelote lorsqu'une fenêtre de vendeur est ouverte."

  --Price
  L["g "] = "o"
  L["s "] = "a"
  L["c"] = "c"

  --misc
  L["LIST_SEPARATOR"] = ", "		--separator used to separate words in a list for exmple ", " in rogue, mage, warrior. This is used to split classes listed in the tooltips under Class:
end

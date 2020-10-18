local L = LibStub("AceLocale-3.0"):NewLocale("AutoProfitX2","ruRU")

if L then
  L["/apx"] = "/apx"
  L["options"] = "options"
  L["Show options panel."] = "Открытие панели настроек."
  L["add"] = "add"
  L["Add items to global ignore list."] = "Добавить предмет в глобальный список исключений."
  L["<item link>[<item link>...]"] = "<item link>[<item link>...]"
  L["rem"] = "rem"
  L["Remove items from global ignore list."] = "Удалить предмет из глобального списка исключений."
  L["me"] = "me"
  L["Add or remove an item from your exception list."] = "Добавить или удалить предмет из вашего списка исключений."
  L["list"] = "list"
  L["List your exceptions."] = "Вывод списка ваших исключений."
		
  --options
  L["Addon Options"] = "Настройки"
  L["Auto Sell"] = "Авто продажа"
  L["Automatically sell junk items when opening vendor window."] = "Автоматическая продажа хлама при открытии окна торговца."
  L["Sales Reports"] = "Отчет о продаже"
  L["Print items being sold in chat frame."] = "Выводить в чат информацию о продаваемых предметах."
  L["Show Profit"] = "Показать прибыль"
  L["Print total profit after sale."] = "Выводить в чат информацию о прибыли после продажи."
  L["Sell Soulbound"] = "Продать персональное"
  L["Sell unusable soulbound items."] = "Продать непригодные персональные предметы."
  L["Button Animation Options"] = "Опции анимации кнопки"
  L["Set up when you want the treasure pile in the button to spin."] =  "Установите когда будет вертеться сокровище в кнопке."
  L["Never spin"] = "Никогда"
  L["Mouse-over and profit"] = "При наводе мыши и прибыли"
  L["Mouse-over"] = "При наводе мыши"
  L["Profits"] = "Прибыли"
  L["Spin when you mouse-over the button and there is junk to vendor."] = "Вертеться при наводе мышки и если есть хлам для продажи торговцу."
  L["Spin every time you mouse over."] = "Вертеться каждый раз при наводе мыши."
  L["Spin every time there is junk to sell."] =  "Вертеться каждый раз при продаже хлама торговцу."
  L["Reset Button Pos"] = "Сброс позиции кнопки."
  L["Reset APX button position on the vendor screen to the top right corner."] = "Сброс позиции кнопки в окне торговца, в правый верхний угол."
  L["Exception List"] = "Список исключений"
  L["Clear Exceptions"] = "Очистить список исключений"
  L["Remove all items from exception list."] = "Удалить все предметы из списка исключения."
  L["Import Exception List"] = "Импортировать список исключений"
  L["Choose character to import exceptions from. Your exceptions will be deleted."] = "Выберите персонажа, скоторого желаете импортировать. Ваш список исключение будет удалён."

  --functions
  L["Added LINK to exception list for all characters."] = function(link) return "Добавлено: "..link..", к списку исключений для всех персонажей." end
  L["Invalid item link provided."] = "Установлена недействительная ссылка предмета."
  L["Removed LINK from all exception lists."] = function(link) return "Удалено: "..link..", из всех списков исключений." end
  L["Removed LINK from exception list."] = function(link) return "Удалено: "..link..", из списка исключений." end
  L["Added LINK to exception list."] = function(link) return "Добавлено: "..link..", к списку исключений." end
  L["Exceptions:"] = "Исключения:"
  L["Your exception list is empty."] = "Ваш список исключений пуст."
  L["Deleted all exceptions."] = "Удалены все исключения."
  L["Exception list imported from NAME on REALM."] = function(name,realm) return "Список исключений импортирован с "..name.." на "..realm.."."	 end
  L["Exception list could not be found for NAME on REALM."] = function(name,realm) return "Список исключений не может быть найдет для "..name.." на "..realm.."." end
  L["Sold LINK."] = function(link) return "Продано: "..link.."." end
  L["Item LINK is junk, but cannot be sold."] = function(link) return "Предмет "..link..", относится к хламу, но не может быть продан." end

  --button functions
  L["Total profits: PROFIT"] = function(profit) return "Всего прибыли: "..profit end
  L["Sell Junk Items"] = "Продать хлам"
  L["You have no junk items in your inventory."] = "В вашем инвентаре нету предметов относящихся к хламу."

  --temporary features
  L["Update Exception List"] = "Обновить список исключений."
  L["Update exception list from pre 2.0 AutoProfitX2 version."] = "Обновить список исключение из версии AutoProfitX2 ниже 2.0."
  L["Exceptions updated."] = "Список исключение обновлен."

  --FeatureFrame
  L["OneKey Sell"] = "Продажа одной кнопкой"
  L["OneKey sell junk items when opening vendor window"] = "Продажа предметов одной кнопкой при открытии окна торговца."

  --Price
  L["g "] = "з "
  L["s "] = "с "
  L["c"] = "м"

  --misc
  L["LIST_SEPARATOR"] = ", "		--separator used to separate words in a list for exmple ", " in rogue, mage, warrior. This is used to split classes listed in the tooltips under Class:
end

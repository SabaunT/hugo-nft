# ethereum-contracts-template
Template for ethereum smart-contracts development

## Tests
For gas-cheap projects local truffle network can be used:
```
npx truffle test

# or with events
npx truffle test --show-events
```

If contract deployment requires much gas, use local ganache-network:
```
ganache-cli -p 7545 -i 5777 --allowUnlimitedContractSize  --gasLimit 0xFFFFFFFFFFFF
npx truffle migrate --reset --network development
npx truffle test --network development

# or with events
npx truffle test --show-events --network development
```

Make sure you have npx package installed globally.

## Dev Notes
##### 1. Насчет хэшей и трэйтов
Хэш валиден до того, как добавлен новый трэйт. Если хэш не валиден, то, по сути,
контракт не работает - не инициализирован. Нельзя что-то минтить, так как ты не знаешь,
что именно ты минтишь (ведь как выглядят атрибуты ты теперь то и не знаешь).

Можно реализовать `mapping(attribute => AttrIpfsInfo)`, где значение это структура, которая
содержит 2 поля: сам хеш и флаг, валиден ли он. При добавлении нового атрибута, хэш становится 
невалидным. Нужна функция, которая возвращает первый `false`, при первом встрече первого невалидного хэша
(или при ситуации, когда мы обновили трэйты - выставить флаг глобальный, что контракт "встал").

Стоит запретить обновлять значение хэша, если оно поставлено и валидно.

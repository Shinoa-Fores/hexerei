# hexerei

<p align="center">
  <img src="https://github.com/Shinoa-Fores/hexerei/blob/master/img/wizard.png?raw=true" alt="taproot wizard"/>
</p>

`hexerei` is a common lisp program that extracts raw inscription data from Bitcoin taproot witness data and generates a binary output file with the results. 


To build, ensure you have <a href="https://www.sbcl.org/">sbcl</a> and <a href="">quicklisp</a> installed, then run `make`.

Some interesting example ordinals are included in the `tx` directory of this repo. The program automatically detects the file type and adds the extension. For example, to view the bitcoin whitepaper, execute:

```
./hexerei tx/85b10531435304cbe47d268106b58b57a4416c76573d4b50fa544432597ad670.txt -o btcwhitepaper
```

```
mc -v btcwhitepaper.pdf
```
<p align="center">
  <img src="https://github.com/Shinoa-Fores/hexerei/blob/master/img/whitepaper.png?raw=true" alt="whitepaper"/>
</p>

Of course the Bitcoin blockchain can play DOOM, we are wizards after all! Just extract from the transaction and run locally in your favourite browser.

```
./hexerei tx/521f8eccffa4c41a3a7728dd012ea5a4a02feed81f41159231251ecf1e5c79da.txt -o doom
```

<p align="center">
  <img src="https://github.com/Shinoa-Fores/hexerei/blob/master/img/doom.png?raw=true" alt="doom"/>
</p>

<p><b>Donate</b> to support future upgrades to this project and many more! BTC: 1Kqig4hSAiuKdJxn8pqDuJmFinkDPUieNy</p>

# hexerei


`inscriptions-parser.py` is a simple Python script that extracts the raw inscription data from the taproot witness data and generates a binary output file with the results.

*The script requires Python 3.*

To use the inscriptions parser script:
(Before I update this, steps 1-4 are totally retarded, one should READ FROM A FUCKING FILE. Step 6 shall be dealt with.)



1. Find your inscription tx on a bitcoin explorer i.e. https://mempool.space
2. Find the witness data in the tx details
3. Copy the witness data hex
4. Paste the witness data hex in the `witness_data` variable within the `inscriptions-parser.py` script
5. Run the script using `python inscriptions-parser.py`
6. Append the appropiate file extension to the output file i.e. `inscription-output.jpg`
7. Open the file and rejoice!



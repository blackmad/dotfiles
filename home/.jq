def tocsv:
  if length == 0 then empty
  else
    (.[0] | keys_unsorted) as $keys
    | (map(keys) | add | unique) as $allkeys
    | ($keys + ($allkeys - $keys)) as $cols
    | ($cols, (.[] as $row | $cols | map($row[.])))
    | @csv
  end ;
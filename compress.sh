#!/usr/bin/env bash

FILES=$(find -type f -not -name '*.gz')

for file in ${FILES}; do
    dest=${file}.gz

    current_size=$(stat -c%s ${file})

    new_size=$(gzip -9 --no-name --stdout ${file} | wc -c)
    if [[ ${new_size} -ge ${current_size} ]]; then
        continue;
    fi

    gzip -9 --no-name --stdout ${file} > ${dest}
done

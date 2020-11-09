#!/usr/bin/env bash

FILES=$(find -type f -not -name '*.gz')
NORMALIZE_LAST_MODIFIED="touch -t 202001010000 -m"

# normalize in order to get reproducible tar balls
${NORMALIZE_LAST_MODIFIED} ${FILES}

for file in ${FILES}; do
    dest=${file}.gz

    current_size=$(stat -c%s ${file})

    new_size=$(gzip -9 --stdout ${file} | wc -c)
    if [[ ${new_size} -ge ${current_size} ]]; then
        continue;
    fi

    gzip -9 --stdout ${file} > ${dest}
done

# normalize in order to get reproducible ETags (based on m-time)
find . -name '*.gz' -exec ${NORMALIZE_LAST_MODIFIED} {} +

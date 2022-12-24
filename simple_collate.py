#!/bin/env python3
from matter import get_entry_names


collate_dict = dict()
collate_dict['ubuntu']      = 'ubuntu'
collate_dict['fedora']      = 'fedora'
collate_dict['linux']       = 'linux'
collate_dict['windows']     = 'microsoft-windows'
collate_dict['firmware']    = 'cog'
collate_dict['settings']    = 'cog'
collate_dict['system']      = 'cog'
collate_dict['setup']       = 'cog'
collate_dict['more']        = 'folder'
collate_dict['options']     = 'folder'


def collate_entry(entry):
    for lexem in entry.split(" "):
        res = collate_dict.get(lexem.lower(), "")
        if res:
            return res
    return "_"

def collate_entries(entries):
    res = []
    for m in entries:
        entryname = m['entryname']
        res.append(collate_entry(entryname))
    return ' '.join(res)


if __name__ == "__main__":
    entries = get_entry_names()
    print(collate_entries(entries))

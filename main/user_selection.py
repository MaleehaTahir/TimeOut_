from collections import defaultdict
import json
import requests
import numpy as np

users_url = "https://gist.github.com/benjambles/ea36b76bc5d8ff09a51def54f6ebd0cb/raw/ee1d0c16eaf373ccca" \
            "dd3d5604a1e0ea307b2ca0/users.json"
venues_url = "https://gist.github.com/benjambles/ea36b76bc5d8ff09a51def54f6ebd0cb/raw/ee1d0c16eaf373ccc" \
             "add3d5604a1e0ea307b2ca0/venues.json"


def main():

    def make_request(url):
        try:
            data = json.loads(requests.get(url).content)
        except requests.exceptions.HTTPError as err:
            raise print(str(err))
        return data

    res_users = make_request(users_url)
    res_venues = make_request(venues_url)

    uniqueNames = []
    for n in res_venues:
        if n["name"] not in uniqueNames:
            uniqueNames.append(n["name"])

    def make_lowercase(obj):
        if hasattr(obj, 'iteritems'):
            ret = {}
            for k, v in obj.iteritems():
                ret[make_lowercase(k)] = make_lowercase(v).replace(' ', '')
            return ret
        elif isinstance(obj, str):
            return obj.lower().replace(' ', '')
        elif hasattr(obj, '__iter__'):
            ret = []
            for item in obj:
                ret.append(make_lowercase(item).replace(' ', ''))
            return ret
        else:
            return obj

    d = defaultdict(list)

    for i in res_venues:
        for j in res_users:
            if len(set(make_lowercase(i['drinks'])).intersection(make_lowercase(j['drinks']))) == 0:
                d[i['name']].append(str("There is nothing for " + j['name'] + " to drink"))
            elif len(set(make_lowercase(i['food'])).intersection(make_lowercase(j['wont_eat']))) >= len(
                    set(make_lowercase(i['food']))):
                d[i['name']].append(str("There is nothing for " + j['name'] + " to eat"))

    json_str = []
    avoided_names = []
    for key, val in d.items():
        json_str.append({"location": key, "reasons": val})
        avoided_names.append(key)

    places_to_visit = list(np.setdiff1d(uniqueNames, avoided_names))
    data = {'places_to_visit': places_to_visit, 'places_to_avoid': json_str}
    print(json.dumps(data, indent=4))


if __name__=='__main__':
    main()
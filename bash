#!/bin/bash
domain=pinnaclecad.com
list_resolver=resolvers.txt
list_wordlist=subdomains.txt
amass_config=~/.config/amass/config.ini
{
    echo "[=] Running Passive Enumeration"
    subfinder -d $domain -o subfinder.txt &>/dev/null
    assetfinder --subs-only $domain | sort -u > assetfinder.txt
    amass enum -passive -norecursive -noalts -d $domain -o amass.txt &>/dev/null
    findomain --quiet -t $domain -u findomain.txt &>/dev/null
    cat subfinder.txt assetfinder.txt amass.txt findomain.txt | grep -F ".$domain" | sort -u > passive.txt
    rm subfinder.txt assetfinder.txt amass.txt findomain.txt
}
{
    echo "[=] Running Active Enumeration"
    shuffledns -d $domain -w $list_wordlist -r $list_resolver -o active_tmp.txt &>/dev/null
    cat active_tmp.txt | grep -F ".$domain" | sed "s/*.//" > active.txt
    rm active_tmp.txt
}
{
    echo "[=] Collecting Active & Passive Enum Result"
    cat active.txt passive.txt | grep -F ".$domain" | sort -u | shuffledns -d $domain -r $list_resolver -o active_passive.txt &>/dev/null
    rm active.txt passive.txt
}

{
    if [[ $(cat active_passive.txt | wc -l) -le 50 ]]
    then
        echo "[=] Running Dual Permute Enumeration"
        dnsgen active_passive.txt | shuffledns -d $domain -r $list_resolver -o permute1_tmp.txt &>/dev/null
        cat permute1_tmp.txt | grep -F ".$domain" > permute1.txt 
        dnsgen permute1.txt | shuffledns -d $domain -r $list_resolver -o permute2_tmp.txt &>/dev/null
        cat permute2_tmp.txt | grep -F ".$domain" > permute2.txt
        cat permute1.txt permute2.txt | grep -F ".$domain" | sort -u > permute.txt
        rm permute1.txt permute1_tmp.txt permute2.txt permute2_tmp.txt
    elif [[ $(cat active_passive.txt | wc -l) -le 100 ]]
    then
        echo "[=] Running Single Permute Enumeration"
        dnsgen active_passive.txt | shuffledns -d $domain -r $list_resolver -o permute_tmp.txt &>/dev/null
        cat permute_tmp.txt | grep -F ".$domain" > permute.txt
        rm permute_tmp.txt
    else
        echo "[=] No Permutation"
    fi
}

{
    echo "[=] Collecting Enumerated Final Result"
    cat active.txt passive.txt active_passive.txt permute.txt 2>/dev/null | grep -F ".$domain" | sort -u > sub.txt
}

{
    mkdir -p $dir
    mv active.txt passive.txt active_passive.txt permute.txt sub.txt sub.httpx $dir 2>/dev/null
}

 {
    echo "[=] Running HTTPx"
    httpx -l sub.txt -silent -o sub.httpx &>/dev/null
    httpx -l sub.txt -csp-probe -silent | grep -F ".$domain" | anew sub.httpx &>/dev/null
    httpx -l sub.txt -tls-probe -silent | grep -F ".$domain" | anew sub.httpx &>/dev/null
}
esac
done


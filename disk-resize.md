#### Rozšíření kapacity disku/partition
Pokud při vytvoření VM ze šablony došlo k navýšení kapacity disku (případně později během provozu, kdy místo nedostačovalo), je nutné v OS expandovat partition oproti fyzické velikosti virtuálního disku. V opačném případě je možné tento krok přeskočit.

Base VM byl nainstalován jako LVM, a proto je nejprve potřeba navýšit kapacitu fyzické partiotion.
<br>Následující postup počítá s fyzickým diskem `/dev/sda`, který má 3 partiotion:
```
/dev/sda1     2048     4095     2048   1M BIOS boot
/dev/sda2     4096  2101247  2097152   1G Linux filesystem  # /boot
/dev/sda3  2101248 33552383 31451136  15G Linux filesystem  # součást LVM
```
Navýšením kapacity disku nám nakonci vznikne volné místo, na které rozšíříme 3. partition tedy `/dev/sda3`. Spustíme program `parted`:
```
sudo parted /dev/sda
```
a v něm provedem příkazy 
```
print free
```
![image.png](/.attachments/image-2b938e0b-26c8-4b1f-90e3-78445a107312.png)

ze kterého nás bude zajímat konec volného místa. Následně příkazem změníme velikost 3. partition (konec volného místa je možno zadat např. jako `19.3GB`).
```
resizepart 3 {konec volneho mista}
``` 
Příkazem `q` opustíme program parted a ověříme, že se místo rozšířilo na 3. partition `/dev/sda3`
```
lsblk
```

![image.png](/.attachments/image-48de7e95-3686-4de8-98ed-f0a57da35433.png)

Provedeme restart serveru
```
sudo shutdown -r 0
```
Po restartu si ověříme, že se partition 3 zvětšila na požadovanou velikost

![image.png](/.attachments/image-9510bec1-c5db-4fa3-95ca-3da4a37fb533.png)

Nyní expandujeme LVM přes celou partition
```
sudo pvresize /dev/sda3
```
![image.png](/.attachments/image-49ef25f5-fb49-44a6-9ed1-89e3e5d9f17a.png)

Zobrazíme si dostupné místo - položka **Free PE**
```
sudo pvdisplay # Free PE
```
![image.png](/.attachments/image-33ec0a2e-3da4-400d-9a54-7a854f75c549.png)

Expandujeme svazek **o dostupné místo**, tj. přičteme dostupné místo
```
sudo lvextend -l +{Free PE} /dev/mapper/ubuntu--vg-ubuntu--lv
```
![image.png](/.attachments/image-c76e6070-663c-4736-ad70-04d450684593.png)

Nakonec rozšíříme file system na dostupné místo
```
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```
![image.png](/.attachments/image-0aa5ce04-99e6-4567-aa46-37b68f2e2b5d.png)


A ověříme příkazem `lsblk`, že u oddílu `/dev/sda3` a svazku `/dev/mapper/ubuntu--vg-ubuntu--lv` došlo k navýšení místa. 

![image.png](/.attachments/image-51f286f8-0072-4344-842d-2180d6b6f54e.png)

Případně pomocí `df -h`, že došlo k navýšení kapacity na root `/` mountpointu

![image.png](/.attachments/image-cce10779-35e7-40e4-ace9-2ec6f3e9b7a4.png)

Dodatečné informace, ze kterých vznikl tento postup:
- https://howtovmlinux.com/articles/vmware/resize-lvm-disk-after-extending-virtual-machine-disk-vmdk.html
- https://askubuntu.com/questions/829392/expand-lvm-logical-volume-on-virtual-machine
- https://fabianlee.org/2016/07/26/ubuntu-extending-a-virtualized-disk-when-using-lvm/

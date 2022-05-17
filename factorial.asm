;-----------------------------
; Klavyeden girilen (en fazla 2 basamaklý) sayý, 
; girildikten sonra ENTER tuþuna basýldýðýnda faktöriyelini hesaplayan 
; ve sonucunu ekrana ve dosyaya yazan assembly program kodu.
;----------------------------------------------------------------------

org 100h
jmp basla 

;---------------------
; Deðiþkenler/Diziler 
;---------------------
sonuc db 160 dup(0)    ; en büyük sonuç (99 faktöriyel), maksimum 156 karakter olacaktýr.
girilen dw 0
sayiGirMsg db 0dh,0ah,"Faktoriyeli alinacak sayiyi girin: $"
sonucMsg db 0dh,0ah,0dh,0ah,"Girilen sayinin faktoriyeli: $" 
dosyaMsg db 0dh,0ah,0dh,0ah,"Cikan sonuc, ...\vdrive\C\odevSonuc.txt dizinine yazdirildi!$" 
dosya db "C:\odevSonuc.txt",0 
dosyaHandle dw ? 
dosyaBuffer db 160 dup(' ')     
dosyaSize dw 0
 
basla:
    lea si,sonuc
    mov byte ptr [si],01h
    
    call sayiGirMesaji
    call girilenSayiyiBelirle
    
    mov dl,al 
    cmp dl,0       ; girilen sayý 0 ise. 
    jne devam
    mov dl,01h     ; 0! = 1
    mov al,dl         
    
    devam:
        cmp dl,25               ; 25!'e kadar, hesaplamadan çýkan sonucun basamak sayýsý, girilen sayýdan düþük oluyor.
        jb yirmiBesAsagi        ; 25! sonrasý, hesaplamadan çýkan sonucun basamak sayýsý, girilen sayýdan büyük oluyor.
        jmp yirmiBesveYukari    ; maksimum 99!'in sonucu, 156 basamaklý bir sayý oluyor. 
            
    yirmiBesAsagi:
        mov girilen,ax          ; 25!'in altýndaki hesaplamalar için, girilen sayýnýn kendisini verebiliriz.
        jmp faktoriyel          ; Böylece 25! altýndaki hesaplamalar için daha az zaman harcamýþ oluyoruz.
        
    yirmiBesveYukari:
        mov girilen,ax  
        add girilen,60
        
    faktoriyel:
        push dx
        call hesapla
        pop dx
        dec dl
        jnz faktoriyel 
        
    call ekranaYazdir 
    call dosyayaYazdir
hlt

;-------------
; Prosedürler 
;-------------
sayiGirMesaji proc
	mov dx,offset sayiGirMsg
	mov ah,09h
	int 21h 
	ret
sayiGirMesaji endp

girilenSayiyiBelirle proc
	mov bx,0000h
	mov dx,0000h
	mov cx,000Ah
				
	yeniKarakterGirisi:
		push bx				; bx, girilmiþ karakterler ile oluþturulan esas sayýdýr.
		
		mov ah,01h			; burada klavyeden girilen karakter okunur.
		int 21h             ; al=girilen karakter
		
		mov ah,00h
		pop bx              ; önceki bx, diðer iþlemlerden etkilenmesin diye stack belleðe atýlýr.
		
		cmp al,0dh			; girilen karakterin, enter olup olmadýðýna bakýlýr.
		jz tamamdir		    ; enter ise karakter girme iþlemi tamamlanmýþtýr.
		sub al,30h			; enter deðilse, girilen ascii karakter, sayýsal deðere çevrilir.
		
		push ax				; önceki sayý 10 ile çarpýlýr ve bir sayý elde edilir, sonraki karakter o sayýya eklenir.
		mov ax,bx
		mul cx				
		mov bx,ax
		pop ax
		add bx,ax
		jmp yeniKarakterGirisi 
		
	tamamdir:
		mov ax,bx			; girilen esas sayý bx'ten ax'e aktarýlýr.
	    ret
girilenSayiyiBelirle endp

hesapla proc
    cmp dl,01h
    jz sonucBir   
    
    lea si,sonuc
    mov dh,10
    mov bx,0000h
    mov cx,girilen 
    
    donDolasYineGel:
        mov al,[si]
        mov ah,00h
        mul dl
        add ax,bx
        div dh                  ; çýkan sonucu sürekli 10'a bölerek, her bir basamak deðerini elde ediyoruz.
        mov [si],ah             ; her bir basamak deðerini, sonuc dizimize birer eleman olarak ekliyoruz.
        inc si
        mov bl,al
        loop donDolasYineGel
    
    sonucBir:  
        ret
hesapla endp   

ekranaYazdir proc
    mov dx,offset sonucMsg
    mov ah,09h
    int 21h
           
    mov bp,0                    ; hesaplamanýn sonucu, basamak basamak sonuc dizisinde ters olarak kayýtlýdýr.
    lea si,sonuc                ; sonuc dizisini tersten okuyup, karakter karakter sonucu ekrana yazdýrýyoruz.
    mov di,si
    mov cx,girilen
    add di,cx
    dec di   
    
    zekiCIPLAK:
        cmp byte ptr [di],00h
        jne zkcplk
        dec di
        jmp zekiCIPLAK
    
    zkcplk:
        mov ah,02h
    
    yaz:
        mov dl,[di]
        add dl,30h  
        mov dosyaBuffer[bp],dl  ; dosyaya yazarken kullanmak için dosyaBuffer dizisini dolduruyoruz.
        inc bp
        int 21h 
        cmp si,di
        je bitis
        dec di
        loop yaz
    
    bitis: 
        mov dosyaSize,bp
        ret
ekranaYazdir endp  

dosyayaYazdir proc
    mov ah,3Ch                  ; yazýlacak dosyayý oluþturuyoruz. 
    mov cx,0000h 
    mov dx,offset dosya
    mov ah,3Ch
    int 21h   
    
    mov dosyaHandle,ax          ; dosyaHandle ile artýk dosyaya her türlü iþlemi yaptýrabiliriz. 
    
    mov ah,40h                  ; dosyaya yazma iþlemi
    mov bx,dosyaHandle
    lea dx,dosyaBuffer 
    mov cx,dosyaSize
    int 21h                     ; C:\emu8086\vdrive\C dizininde odevSonuc.txt dosyasýna yazýlacaktýr.
    
    mov ah,3eh                  ; burada dosyayý kapatýyoruz.
    mov bx,dosyaHandle
    int 21h  
    
    mov dx,offset dosyaMsg      ; dosyanýn baþarýyla yazýldýðýný ekranda bildiriyoruz.
    mov ah,09h
    int 21h
    ret
dosyayaYazdir endp

; Zeki ÇIPLAK
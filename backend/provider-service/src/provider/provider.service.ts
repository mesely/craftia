
import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class ProviderService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ProviderService.name);
  private readonly apiKey = process.env.GOOGLE_PLACES_API_KEY;

  // --- TURKEY_DATA LİSTESİ BURAYA (Senin listen gelecek) ---
  private readonly TURKEY_DATA = [
  { il: 'Adana', ilce: 'Aladağ' }, { il: 'Adana', ilce: 'Ceyhan' }, { il: 'Adana', ilce: 'Feke' },
  { il: 'Adana', ilce: 'Karaisalı' }, { il: 'Adana', ilce: 'Karataş' }, { il: 'Adana', ilce: 'Kozan' },
  { il: 'Adana', ilce: 'Pozantı' }, { il: 'Adana', ilce: 'Saimbeyli' }, { il: 'Adana', ilce: 'Sarıçam' },
  { il: 'Adana', ilce: 'Seyhan' }, { il: 'Adana', ilce: 'Tufanbeyli' }, { il: 'Adana', ilce: 'Yumurtalık' },
  { il: 'Adana', ilce: 'Yüreğir' }, { il: 'Adana', ilce: 'Çukurova' }, { il: 'Adana', ilce: 'İmamoğlu' },
  { il: 'Adıyaman', ilce: 'Adıyaman Merkez' }, { il: 'Adıyaman', ilce: 'Besni' }, { il: 'Adıyaman', ilce: 'Gerger' },
  { il: 'Adıyaman', ilce: 'Gölbaşı' }, { il: 'Adıyaman', ilce: 'Kahta' }, { il: 'Adıyaman', ilce: 'Samsat' },
  { il: 'Adıyaman', ilce: 'Sincik' }, { il: 'Adıyaman', ilce: 'Tut' }, { il: 'Adıyaman', ilce: 'Çelikhan' },
  { il: 'Afyonkarahisar', ilce: 'Afyonkarahisar Merkez' }, { il: 'Afyonkarahisar', ilce: 'Bayat' }, { il: 'Afyonkarahisar', ilce: 'Başmakçı' },
  { il: 'Afyonkarahisar', ilce: 'Bolvadin' }, { il: 'Afyonkarahisar', ilce: 'Dazkırı' }, { il: 'Afyonkarahisar', ilce: 'Dinar' },
  { il: 'Afyonkarahisar', ilce: 'Emirdağ' }, { il: 'Afyonkarahisar', ilce: 'Evciler' }, { il: 'Afyonkarahisar', ilce: 'Hocalar' },
  { il: 'Afyonkarahisar', ilce: 'Kızılören' }, { il: 'Afyonkarahisar', ilce: 'Sandıklı' }, { il: 'Afyonkarahisar', ilce: 'Sinanpaşa' },
  { il: 'Afyonkarahisar', ilce: 'Sultandağı' }, { il: 'Afyonkarahisar', ilce: 'Çay' }, { il: 'Afyonkarahisar', ilce: 'Çobanlar' },
  { il: 'Afyonkarahisar', ilce: 'İhsaniye' }, { il: 'Afyonkarahisar', ilce: 'İscehisar' }, { il: 'Afyonkarahisar', ilce: 'Şuhut' },
  { il: 'Aksaray', ilce: 'Aksaray Merkez' }, { il: 'Aksaray', ilce: 'Ağaçören' }, { il: 'Aksaray', ilce: 'Eskil' },
  { il: 'Aksaray', ilce: 'Gülağaç' }, { il: 'Aksaray', ilce: 'Güzelyurt' }, { il: 'Aksaray', ilce: 'Ortaköy' },
  { il: 'Aksaray', ilce: 'Sarıyahşi' }, { il: 'Aksaray', ilce: 'Sultanhanı' },
  { il: 'Amasya', ilce: 'Amasya Merkez' }, { il: 'Amasya', ilce: 'Göynücek' }, { il: 'Amasya', ilce: 'Gümüşhacıköy' },
  { il: 'Amasya', ilce: 'Hamamözü' }, { il: 'Amasya', ilce: 'Merzifon' }, { il: 'Amasya', ilce: 'Suluova' }, { il: 'Amasya', ilce: 'Taşova' },
  { il: 'Ankara', ilce: 'Akyurt' }, { il: 'Ankara', ilce: 'Altındağ' }, { il: 'Ankara', ilce: 'Ayaş' },
  { il: 'Ankara', ilce: 'Bala' }, { il: 'Ankara', ilce: 'Beypazarı' }, { il: 'Ankara', ilce: 'Elmadağ' },
  { il: 'Ankara', ilce: 'Etimesgut' }, { il: 'Ankara', ilce: 'Evren' }, { il: 'Ankara', ilce: 'Gölbaşı' },
  { il: 'Ankara', ilce: 'Güdül' }, { il: 'Ankara', ilce: 'Haymana' }, { il: 'Ankara', ilce: 'Kahramankazan' },
  { il: 'Ankara', ilce: 'Kalecik' }, { il: 'Ankara', ilce: 'Keçiören' }, { il: 'Ankara', ilce: 'Kızılcahamam' },
  { il: 'Ankara', ilce: 'Mamak' }, { il: 'Ankara', ilce: 'Nallıhan' }, { il: 'Ankara', ilce: 'Polatlı' },
  { il: 'Ankara', ilce: 'Pursaklar' }, { il: 'Ankara', ilce: 'Sincan' }, { il: 'Ankara', ilce: 'Yenimahalle' },
  { il: 'Ankara', ilce: 'Çamlıdere' }, { il: 'Ankara', ilce: 'Çankaya' }, { il: 'Ankara', ilce: 'Çubuk' }, { il: 'Ankara', ilce: 'Şereflikoçhisar' },
  { il: 'Antalya', ilce: 'Akseki' }, { il: 'Antalya', ilce: 'Aksu' }, { il: 'Antalya', ilce: 'Alanya' },
  { il: 'Antalya', ilce: 'Demre' }, { il: 'Antalya', ilce: 'Döşemealtı' }, { il: 'Antalya', ilce: 'Elmalı' },
  { il: 'Antalya', ilce: 'Finike' }, { il: 'Antalya', ilce: 'Gazipaşa' }, { il: 'Antalya', ilce: 'Gündoğmuş' },
  { il: 'Antalya', ilce: 'Kaş' }, { il: 'Antalya', ilce: 'Kemer' }, { il: 'Antalya', ilce: 'Kepez' },
  { il: 'Antalya', ilce: 'Konyaaltı' }, { il: 'Antalya', ilce: 'Korkuteli' }, { il: 'Antalya', ilce: 'Kumluca' },
  { il: 'Antalya', ilce: 'Manavgat' }, { il: 'Antalya', ilce: 'Muratpaşa' }, { il: 'Antalya', ilce: 'Serik' }, { il: 'Antalya', ilce: 'İbradı' },
  { il: 'Ardahan', ilce: 'Ardahan Merkez' }, { il: 'Ardahan', ilce: 'Damal' }, { il: 'Ardahan', ilce: 'Göle' },
  { il: 'Ardahan', ilce: 'Hanak' }, { il: 'Ardahan', ilce: 'Posof' }, { il: 'Ardahan', ilce: 'Çıldır' },
  { il: 'Artvin', ilce: 'Ardanuç' }, { il: 'Artvin', ilce: 'Arhavi' }, { il: 'Artvin', ilce: 'Artvin Merkez' },
  { il: 'Artvin', ilce: 'Borçka' }, { il: 'Artvin', ilce: 'Hopa' }, { il: 'Artvin', ilce: 'Kemalpaşa' },
  { il: 'Artvin', ilce: 'Murgul' }, { il: 'Artvin', ilce: 'Yusufeli' }, { il: 'Artvin', ilce: 'Şavşat' },
  { il: 'Aydın', ilce: 'Bozdoğan' }, { il: 'Aydın', ilce: 'Buharkent' }, { il: 'Aydın', ilce: 'Didim' },
  { il: 'Aydın', ilce: 'Efeler' }, { il: 'Aydın', ilce: 'Germencik' }, { il: 'Aydın', ilce: 'Karacasu' },
  { il: 'Aydın', ilce: 'Karpuzlu' }, { il: 'Aydın', ilce: 'Koçarlı' }, { il: 'Aydın', ilce: 'Kuyucak' },
  { il: 'Aydın', ilce: 'Kuşadası' }, { il: 'Aydın', ilce: 'Köşk' }, { il: 'Aydın', ilce: 'Nazilli' },
  { il: 'Aydın', ilce: 'Sultanhisar' }, { il: 'Aydın', ilce: 'Söke' }, { il: 'Aydın', ilce: 'Yenipazar' },
  { il: 'Aydın', ilce: 'Çine' }, { il: 'Aydın', ilce: 'İncirliova' },
  { il: 'Ağrı', ilce: 'Ağrı Merkez' }, { il: 'Ağrı', ilce: 'Diyadin' }, { il: 'Ağrı', ilce: 'Doğubayazıt' },
  { il: 'Ağrı', ilce: 'Eleşkirt' }, { il: 'Ağrı', ilce: 'Hamur' }, { il: 'Ağrı', ilce: 'Patnos' },
  { il: 'Ağrı', ilce: 'Taşlıçay' }, { il: 'Ağrı', ilce: 'Tutak' },
  { il: 'Balıkesir', ilce: 'Altıeylül' }, { il: 'Balıkesir', ilce: 'Ayvalık' }, { il: 'Balıkesir', ilce: 'Balya' },
  { il: 'Balıkesir', ilce: 'Bandırma' }, { il: 'Balıkesir', ilce: 'Bigadiç' }, { il: 'Balıkesir', ilce: 'Burhaniye' },
  { il: 'Balıkesir', ilce: 'Dursunbey' }, { il: 'Balıkesir', ilce: 'Edremit' }, { il: 'Balıkesir', ilce: 'Erdek' },
  { il: 'Balıkesir', ilce: 'Gömeç' }, { il: 'Balıkesir', ilce: 'Gönen' }, { il: 'Balıkesir', ilce: 'Havran' },
  { il: 'Balıkesir', ilce: 'Karesi' }, { il: 'Balıkesir', ilce: 'Kepsut' }, { il: 'Balıkesir', ilce: 'Manyas' },
  { il: 'Balıkesir', ilce: 'Marmara' }, { il: 'Balıkesir', ilce: 'Savaştepe' }, { il: 'Balıkesir', ilce: 'Susurluk' },
  { il: 'Balıkesir', ilce: 'Sındırgı' }, { il: 'Balıkesir', ilce: 'İvrindi' },
  { il: 'Bartın', ilce: 'Amasra' }, { il: 'Bartın', ilce: 'Bartın Merkez' }, { il: 'Bartın', ilce: 'Kurucaşile' }, { il: 'Bartın', ilce: 'Ulus' },
  { il: 'Batman', ilce: 'Batman Merkez' }, { il: 'Batman', ilce: 'Beşiri' }, { il: 'Batman', ilce: 'Gercüş' },
  { il: 'Batman', ilce: 'Hasankeyf' }, { il: 'Batman', ilce: 'Kozluk' }, { il: 'Batman', ilce: 'Sason' },
  { il: 'Bayburt', ilce: 'Aydıntepe' }, { il: 'Bayburt', ilce: 'Bayburt Merkez' }, { il: 'Bayburt', ilce: 'Demirözü' },
  { il: 'Bilecik', ilce: 'Bilecik Merkez' }, { il: 'Bilecik', ilce: 'Bozüyük' }, { il: 'Bilecik', ilce: 'Gölpazarı' },
  { il: 'Bilecik', ilce: 'Osmaneli' }, { il: 'Bilecik', ilce: 'Pazaryeri' }, { il: 'Bilecik', ilce: 'Söğüt' },
  { il: 'Bilecik', ilce: 'Yenipazar' }, { il: 'Bilecik', ilce: 'İnhisar' },
  { il: 'Bingöl', ilce: 'Adaklı' }, { il: 'Bingöl', ilce: 'Bingöl Merkez' }, { il: 'Bingöl', ilce: 'Genç' },
  { il: 'Bingöl', ilce: 'Karlıova' }, { il: 'Bingöl', ilce: 'Kiğı' }, { il: 'Bingöl', ilce: 'Solhan' },
  { il: 'Bingöl', ilce: 'Yayladere' }, { il: 'Bingöl', ilce: 'Yedisu' },
  { il: 'Bitlis', ilce: 'Adilcevaz' }, { il: 'Bitlis', ilce: 'Ahlat' }, { il: 'Bitlis', ilce: 'Bitlis Merkez' },
  { il: 'Bitlis', ilce: 'Güroymak' }, { il: 'Bitlis', ilce: 'Hizan' }, { il: 'Bitlis', ilce: 'Mutki' }, { il: 'Bitlis', ilce: 'Tatvan' },
  { il: 'Bolu', ilce: 'Bolu Merkez' }, { il: 'Bolu', ilce: 'Dörtdivan' }, { il: 'Bolu', ilce: 'Gerede' },
  { il: 'Bolu', ilce: 'Göynük' }, { il: 'Bolu', ilce: 'Kıbrıscık' }, { il: 'Bolu', ilce: 'Mengen' },
  { il: 'Bolu', ilce: 'Mudurnu' }, { il: 'Bolu', ilce: 'Seben' }, { il: 'Bolu', ilce: 'Yeniçağa' },
  { il: 'Burdur', ilce: 'Altınyayla' }, { il: 'Burdur', ilce: 'Ağlasun' }, { il: 'Burdur', ilce: 'Bucak' },
  { il: 'Burdur', ilce: 'Burdur Merkez' }, { il: 'Burdur', ilce: 'Gölhisar' }, { il: 'Burdur', ilce: 'Karamanlı' },
  { il: 'Burdur', ilce: 'Kemer' }, { il: 'Burdur', ilce: 'Tefenni' }, { il: 'Burdur', ilce: 'Yeşilova' },
  { il: 'Burdur', ilce: 'Çavdır' }, { il: 'Burdur', ilce: 'Çeltikçi' },
  { il: 'Bursa', ilce: 'Büyükorhan' }, { il: 'Bursa', ilce: 'Gemlik' }, { il: 'Bursa', ilce: 'Gürsu' },
  { il: 'Bursa', ilce: 'Harmancık' }, { il: 'Bursa', ilce: 'Karacabey' }, { il: 'Bursa', ilce: 'Keles' },
  { il: 'Bursa', ilce: 'Kestel' }, { il: 'Bursa', ilce: 'Mudanya' }, { il: 'Bursa', ilce: 'Mustafakemalpaşa' },
  { il: 'Bursa', ilce: 'Nilüfer' }, { il: 'Bursa', ilce: 'Orhaneli' }, { il: 'Bursa', ilce: 'Orhangazi' },
  { il: 'Bursa', ilce: 'Osmangazi' }, { il: 'Bursa', ilce: 'Yenişehir' }, { il: 'Bursa', ilce: 'Yıldırım' },
  { il: 'Bursa', ilce: 'İnegöl' }, { il: 'Bursa', ilce: 'İznik' },
  { il: 'Denizli', ilce: 'Acıpayam' }, { il: 'Denizli', ilce: 'Babadağ' }, { il: 'Denizli', ilce: 'Baklan' },
  { il: 'Denizli', ilce: 'Bekilli' }, { il: 'Denizli', ilce: 'Beyağaç' }, { il: 'Denizli', ilce: 'Bozkurt' },
  { il: 'Denizli', ilce: 'Buldan' }, { il: 'Denizli', ilce: 'Güney' }, { il: 'Denizli', ilce: 'Honaz' },
  { il: 'Denizli', ilce: 'Kale' }, { il: 'Denizli', ilce: 'Merkezefendi' }, { il: 'Denizli', ilce: 'Pamukkale' },
  { il: 'Denizli', ilce: 'Sarayköy' }, { il: 'Denizli', ilce: 'Serinhisar' }, { il: 'Denizli', ilce: 'Tavas' },
  { il: 'Denizli', ilce: 'Çal' }, { il: 'Denizli', ilce: 'Çameli' }, { il: 'Denizli', ilce: 'Çardak' }, { il: 'Denizli', ilce: 'Çivril' },
  { il: 'Diyarbakır', ilce: 'Bağlar' }, { il: 'Diyarbakır', ilce: 'Bismil' }, { il: 'Diyarbakır', ilce: 'Dicle' },
  { il: 'Diyarbakır', ilce: 'Ergani' }, { il: 'Diyarbakır', ilce: 'Eğil' }, { il: 'Diyarbakır', ilce: 'Hani' },
  { il: 'Diyarbakır', ilce: 'Hazro' }, { il: 'Diyarbakır', ilce: 'Kayapınar' }, { il: 'Diyarbakır', ilce: 'Kocaköy' },
  { il: 'Diyarbakır', ilce: 'Kulp' }, { il: 'Diyarbakır', ilce: 'Lice' }, { il: 'Diyarbakır', ilce: 'Silvan' },
  { il: 'Diyarbakır', ilce: 'Sur' }, { il: 'Diyarbakır', ilce: 'Yenişehir' }, { il: 'Diyarbakır', ilce: 'Çermik' },
  { il: 'Diyarbakır', ilce: 'Çüngüş' }, { il: 'Diyarbakır', ilce: 'Çınar' },
  { il: 'Düzce', ilce: 'Akçakoca' }, { il: 'Düzce', ilce: 'Cumayeri' }, { il: 'Düzce', ilce: 'Düzce Merkez' },
  { il: 'Düzce', ilce: 'Gölyaka' }, { il: 'Düzce', ilce: 'Gümüşova' }, { il: 'Düzce', ilce: 'Kaynaşlı' },
  { il: 'Düzce', ilce: 'Yığılca' }, { il: 'Düzce', ilce: 'Çilimli' },
  { il: 'Edirne', ilce: 'Edirne Merkez' }, { il: 'Edirne', ilce: 'Enez' }, { il: 'Edirne', ilce: 'Havsa' },
  { il: 'Edirne', ilce: 'Keşan' }, { il: 'Edirne', ilce: 'Lalapaşa' }, { il: 'Edirne', ilce: 'Meriç' },
  { il: 'Edirne', ilce: 'Süloğlu' }, { il: 'Edirne', ilce: 'Uzunköprü' }, { il: 'Edirne', ilce: 'İpsala' },
  { il: 'Elazığ', ilce: 'Alacakaya' }, { il: 'Elazığ', ilce: 'Arıcak' }, { il: 'Elazığ', ilce: 'Ağın' },
  { il: 'Elazığ', ilce: 'Baskil' }, { il: 'Elazığ', ilce: 'Elazığ Merkez' }, { il: 'Elazığ', ilce: 'Karakoçan' },
  { il: 'Elazığ', ilce: 'Keban' }, { il: 'Elazığ', ilce: 'Kovancılar' }, { il: 'Elazığ', ilce: 'Maden' },
  { il: 'Elazığ', ilce: 'Palu' }, { il: 'Elazığ', ilce: 'Sivrice' },
  { il: 'Erzincan', ilce: 'Erzincan Merkez' }, { il: 'Erzincan', ilce: 'Kemah' }, { il: 'Erzincan', ilce: 'Kemaliye' },
  { il: 'Erzincan', ilce: 'Otlukbeli' }, { il: 'Erzincan', ilce: 'Refahiye' }, { il: 'Erzincan', ilce: 'Tercan' },
  { il: 'Erzincan', ilce: 'Çayırlı' }, { il: 'Erzincan', ilce: 'Üzümlü' }, { il: 'Erzincan', ilce: 'İliç' },
  { il: 'Erzurum', ilce: 'Aziziye' }, { il: 'Erzurum', ilce: 'Aşkale' }, { il: 'Erzurum', ilce: 'Horasan' },
  { il: 'Erzurum', ilce: 'Hınıs' }, { il: 'Erzurum', ilce: 'Karayazı' }, { il: 'Erzurum', ilce: 'Karaçoban' },
  { il: 'Erzurum', ilce: 'Köprüköy' }, { il: 'Erzurum', ilce: 'Narman' }, { il: 'Erzurum', ilce: 'Oltu' },
  { il: 'Erzurum', ilce: 'Olur' }, { il: 'Erzurum', ilce: 'Palandöken' }, { il: 'Erzurum', ilce: 'Pasinler' },
  { il: 'Erzurum', ilce: 'Pazaryolu' }, { il: 'Erzurum', ilce: 'Tekman' }, { il: 'Erzurum', ilce: 'Tortum' },
  { il: 'Erzurum', ilce: 'Uzundere' }, { il: 'Erzurum', ilce: 'Yakutiye' }, { il: 'Erzurum', ilce: 'Çat' },
  { il: 'Erzurum', ilce: 'İspir' }, { il: 'Erzurum', ilce: 'Şenkaya' },
  { il: 'Eskişehir', ilce: 'Alpu' }, { il: 'Eskişehir', ilce: 'Beylikova' }, { il: 'Eskişehir', ilce: 'Günyüzü' },
  { il: 'Eskişehir', ilce: 'Han' }, { il: 'Eskişehir', ilce: 'Mahmudiye' }, { il: 'Eskişehir', ilce: 'Mihalgazi' },
  { il: 'Eskişehir', ilce: 'Mihalıççık' }, { il: 'Eskişehir', ilce: 'Odunpazarı' }, { il: 'Eskişehir', ilce: 'Sarıcakaya' },
  { il: 'Eskişehir', ilce: 'Seyitgazi' }, { il: 'Eskişehir', ilce: 'Sivrihisar' }, { il: 'Eskişehir', ilce: 'Tepebaşı' },
  { il: 'Eskişehir', ilce: 'Çifteler' }, { il: 'Eskişehir', ilce: 'İnönü' },
  { il: 'Gaziantep', ilce: 'Araban' }, { il: 'Gaziantep', ilce: 'Karkamış' }, { il: 'Gaziantep', ilce: 'Nizip' },
  { il: 'Gaziantep', ilce: 'Nurdağı' }, { il: 'Gaziantep', ilce: 'Oğuzeli' }, { il: 'Gaziantep', ilce: 'Yavuzeli' },
  { il: 'Gaziantep', ilce: 'İslahiye' }, { il: 'Gaziantep', ilce: 'Şahinbey' }, { il: 'Gaziantep', ilce: 'Şehitkamil' },
  { il: 'Giresun', ilce: 'Alucra' }, { il: 'Giresun', ilce: 'Bulancak' }, { il: 'Giresun', ilce: 'Dereli' },
  { il: 'Giresun', ilce: 'Doğankent' }, { il: 'Giresun', ilce: 'Espiye' }, { il: 'Giresun', ilce: 'Eynesil' },
  { il: 'Giresun', ilce: 'Giresun Merkez' }, { il: 'Giresun', ilce: 'Görele' }, { il: 'Giresun', ilce: 'Güce' },
  { il: 'Giresun', ilce: 'Keşap' }, { il: 'Giresun', ilce: 'Piraziz' }, { il: 'Giresun', ilce: 'Tirebolu' },
  { il: 'Giresun', ilce: 'Yağlıdere' }, { il: 'Giresun', ilce: 'Çamoluk' }, { il: 'Giresun', ilce: 'Çanakçı' }, { il: 'Giresun', ilce: 'Şebinkarahisar' },
  { il: 'Gümüşhane', ilce: 'Gümüşhane Merkez' }, { il: 'Gümüşhane', ilce: 'Kelkit' }, { il: 'Gümüşhane', ilce: 'Köse' },
  { il: 'Gümüşhane', ilce: 'Kürtün' }, { il: 'Gümüşhane', ilce: 'Torul' }, { il: 'Gümüşhane', ilce: 'Şiran' },
  { il: 'Hakkâri', ilce: 'Derecik' }, { il: 'Hakkâri', ilce: 'Hakkâri Merkez' }, { il: 'Hakkâri', ilce: 'Yüksekova' },
  { il: 'Hakkâri', ilce: 'Çukurca' }, { il: 'Hakkâri', ilce: 'Şemdinli' },
  { il: 'Hatay', ilce: 'Altınözü' }, { il: 'Hatay', ilce: 'Antakya' }, { il: 'Hatay', ilce: 'Arsuz' },
  { il: 'Hatay', ilce: 'Belen' }, { il: 'Hatay', ilce: 'Defne' }, { il: 'Hatay', ilce: 'Dörtyol' },
  { il: 'Hatay', ilce: 'Erzin' }, { il: 'Hatay', ilce: 'Hassa' }, { il: 'Hatay', ilce: 'Kumlu' },
  { il: 'Hatay', ilce: 'Kırıkhan' }, { il: 'Hatay', ilce: 'Payas' }, { il: 'Hatay', ilce: 'Reyhanlı' },
  { il: 'Hatay', ilce: 'Samandağ' }, { il: 'Hatay', ilce: 'Yayladağı' }, { il: 'Hatay', ilce: 'İskenderun' },
  { il: 'Isparta', ilce: 'Aksu' }, { il: 'Isparta', ilce: 'Atabey' }, { il: 'Isparta', ilce: 'Eğirdir' },
  { il: 'Isparta', ilce: 'Gelendost' }, { il: 'Isparta', ilce: 'Gönen' }, { il: 'Isparta', ilce: 'Isparta Merkez' },
  { il: 'Isparta', ilce: 'Keçiborlu' }, { il: 'Isparta', ilce: 'Senirkent' }, { il: 'Isparta', ilce: 'Sütçüler' },
  { il: 'Isparta', ilce: 'Uluborlu' }, { il: 'Isparta', ilce: 'Yalvaç' }, { il: 'Isparta', ilce: 'Yenişarbademli' }, { il: 'Isparta', ilce: 'Şarkikaraağaç' },
  { il: 'Iğdır', ilce: 'Aralık' }, { il: 'Iğdır', ilce: 'Iğdır Merkez' }, { il: 'Iğdır', ilce: 'Karakoyunlu' }, { il: 'Iğdır', ilce: 'Tuzluca' },
  { il: 'Kahramanmaraş', ilce: 'Afşin' }, { il: 'Kahramanmaraş', ilce: 'Andırın' }, { il: 'Kahramanmaraş', ilce: 'Dulkadiroğlu' },
  { il: 'Kahramanmaraş', ilce: 'Ekinözü' }, { il: 'Kahramanmaraş', ilce: 'Elbistan' }, { il: 'Kahramanmaraş', ilce: 'Göksun' },
  { il: 'Kahramanmaraş', ilce: 'Nurhak' }, { il: 'Kahramanmaraş', ilce: 'Onikişubat' }, { il: 'Kahramanmaraş', ilce: 'Pazarcık' },
  { il: 'Kahramanmaraş', ilce: 'Türkoğlu' }, { il: 'Kahramanmaraş', ilce: 'Çağlayancerit' },
  { il: 'Karabük', ilce: 'Eflani' }, { il: 'Karabük', ilce: 'Eskipazar' }, { il: 'Karabük', ilce: 'Karabük Merkez' },
  { il: 'Karabük', ilce: 'Ovacık' }, { il: 'Karabük', ilce: 'Safranbolu' }, { il: 'Karabük', ilce: 'Yenice' },
  { il: 'Karaman', ilce: 'Ayrancı' }, { il: 'Karaman', ilce: 'Başyayla' }, { il: 'Karaman', ilce: 'Ermenek' },
  { il: 'Karaman', ilce: 'Karaman Merkez' }, { il: 'Karaman', ilce: 'Kazımkarabekir' }, { il: 'Karaman', ilce: 'Sarıveliler' },
  { il: 'Kars', ilce: 'Akyaka' }, { il: 'Kars', ilce: 'Arpaçay' }, { il: 'Kars', ilce: 'Digor' },
  { il: 'Kars', ilce: 'Kars Merkez' }, { il: 'Kars', ilce: 'Kağızman' }, { il: 'Kars', ilce: 'Sarıkamış' },
  { il: 'Kars', ilce: 'Selim' }, { il: 'Kars', ilce: 'Susuz' },
  { il: 'Kastamonu', ilce: 'Abana' }, { il: 'Kastamonu', ilce: 'Araç' }, { il: 'Kastamonu', ilce: 'Azdavay' },
  { il: 'Kastamonu', ilce: 'Ağlı' }, { il: 'Kastamonu', ilce: 'Bozkurt' }, { il: 'Kastamonu', ilce: 'Cide' },
  { il: 'Kastamonu', ilce: 'Daday' }, { il: 'Kastamonu', ilce: 'Devrekani' }, { il: 'Kastamonu', ilce: 'Doğanyurt' },
  { il: 'Kastamonu', ilce: 'Hanönü' }, { il: 'Kastamonu', ilce: 'Kastamonu Merkez' }, { il: 'Kastamonu', ilce: 'Küre' },
  { il: 'Kastamonu', ilce: 'Pınarbaşı' }, { il: 'Kastamonu', ilce: 'Seydiler' }, { il: 'Kastamonu', ilce: 'Taşköprü' },
  { il: 'Kastamonu', ilce: 'Tosya' }, { il: 'Kastamonu', ilce: 'Çatalzeytin' }, { il: 'Kastamonu', ilce: 'İhsangazi' },
  { il: 'Kastamonu', ilce: 'İnebolu' }, { il: 'Kastamonu', ilce: 'Şenpazar' },
  { il: 'Kayseri', ilce: 'Akkışla' }, { il: 'Kayseri', ilce: 'Bünyan' }, { il: 'Kayseri', ilce: 'Develi' },
  { il: 'Kayseri', ilce: 'Felahiye' }, { il: 'Kayseri', ilce: 'Hacılar' }, { il: 'Kayseri', ilce: 'Kocasinan' },
  { il: 'Kayseri', ilce: 'Melikgazi' }, { il: 'Kayseri', ilce: 'Pınarbaşı' }, { il: 'Kayseri', ilce: 'Sarıoğlan' },
  { il: 'Kayseri', ilce: 'Sarız' }, { il: 'Kayseri', ilce: 'Talas' }, { il: 'Kayseri', ilce: 'Tomarza' },
  { il: 'Kayseri', ilce: 'Yahyalı' }, { il: 'Kayseri', ilce: 'Yeşilhisar' }, { il: 'Kayseri', ilce: 'Özvatan' }, { il: 'Kayseri', ilce: 'İncesu' },
  { il: 'Kilis', ilce: 'Elbeyli' }, { il: 'Kilis', ilce: 'Kilis Merkez' }, { il: 'Kilis', ilce: 'Musabeyli' }, { il: 'Kilis', ilce: 'Polateli' },
  { il: 'Kocaeli', ilce: 'Başiskele' }, { il: 'Kocaeli', ilce: 'Darıca' }, { il: 'Kocaeli', ilce: 'Derince' },
  { il: 'Kocaeli', ilce: 'Dilovası' }, { il: 'Kocaeli', ilce: 'Gebze' }, { il: 'Kocaeli', ilce: 'Gölcük' },
  { il: 'Kocaeli', ilce: 'Kandıra' }, { il: 'Kocaeli', ilce: 'Karamürsel' }, { il: 'Kocaeli', ilce: 'Kartepe' },
  { il: 'Kocaeli', ilce: 'Körfez' }, { il: 'Kocaeli', ilce: 'Çayırova' }, { il: 'Kocaeli', ilce: 'İzmit' },
  { il: 'Konya', ilce: 'Ahırlı' }, { il: 'Konya', ilce: 'Akören' }, { il: 'Konya', ilce: 'Akşehir' },
  { il: 'Konya', ilce: 'Altınekin' }, { il: 'Konya', ilce: 'Beyşehir' }, { il: 'Konya', ilce: 'Bozkır' },
  { il: 'Konya', ilce: 'Cihanbeyli' }, { il: 'Konya', ilce: 'Derbent' }, { il: 'Konya', ilce: 'Derebucak' },
  { il: 'Konya', ilce: 'Doğanhisar' }, { il: 'Konya', ilce: 'Emirgazi' }, { il: 'Konya', ilce: 'Ereğli' },
  { il: 'Konya', ilce: 'Güneysınır' }, { il: 'Konya', ilce: 'Hadim' }, { il: 'Konya', ilce: 'Halkapınar' },
  { il: 'Konya', ilce: 'Hüyük' }, { il: 'Konya', ilce: 'Ilgın' }, { il: 'Konya', ilce: 'Kadınhanı' },
  { il: 'Konya', ilce: 'Karapınar' }, { il: 'Konya', ilce: 'Karatay' }, { il: 'Konya', ilce: 'Kulu' },
  { il: 'Konya', ilce: 'Meram' }, { il: 'Konya', ilce: 'Sarayönü' }, { il: 'Konya', ilce: 'Selçuklu' },
  { il: 'Konya', ilce: 'Seydişehir' }, { il: 'Konya', ilce: 'Taşkent' }, { il: 'Konya', ilce: 'Tuzlukçu' },
  { il: 'Konya', ilce: 'Yalıhüyük' }, { il: 'Konya', ilce: 'Yunak' }, { il: 'Konya', ilce: 'Çeltik' }, { il: 'Konya', ilce: 'Çumra' },
  { il: 'Kütahya', ilce: 'Altıntaş' }, { il: 'Kütahya', ilce: 'Aslanapa' }, { il: 'Kütahya', ilce: 'Domaniç' },
  { il: 'Kütahya', ilce: 'Dumlupınar' }, { il: 'Kütahya', ilce: 'Emet' }, { il: 'Kütahya', ilce: 'Gediz' },
  { il: 'Kütahya', ilce: 'Hisarcık' }, { il: 'Kütahya', ilce: 'Kütahya Merkez' }, { il: 'Kütahya', ilce: 'Pazarlar' },
  { il: 'Kütahya', ilce: 'Simav' }, { il: 'Kütahya', ilce: 'Tavşanlı' }, { il: 'Kütahya', ilce: 'Çavdarhisar' }, { il: 'Kütahya', ilce: 'Şaphane' },
  { il: 'Kırklareli', ilce: 'Babaeski' }, { il: 'Kırklareli', ilce: 'Demirköy' }, { il: 'Kırklareli', ilce: 'Kofçaz' },
  { il: 'Kırklareli', ilce: 'Kırklareli Merkez' }, { il: 'Kırklareli', ilce: 'Lüleburgaz' }, { il: 'Kırklareli', ilce: 'Pehlivanköy' },
  { il: 'Kırklareli', ilce: 'Pınarhisar' }, { il: 'Kırklareli', ilce: 'Vize' },
  { il: 'Kırıkkale', ilce: 'Bahşili' }, { il: 'Kırıkkale', ilce: 'Balışeyh' }, { il: 'Kırıkkale', ilce: 'Delice' },
  { il: 'Kırıkkale', ilce: 'Karakeçili' }, { il: 'Kırıkkale', ilce: 'Keskin' }, { il: 'Kırıkkale', ilce: 'Kırıkkale Merkez' },
  { il: 'Kırıkkale', ilce: 'Sulakyurt' }, { il: 'Kırıkkale', ilce: 'Yahşihan' }, { il: 'Kırıkkale', ilce: 'Çelebi' },
  { il: 'Kırşehir', ilce: 'Akpınar' }, { il: 'Kırşehir', ilce: 'Akçakent' }, { il: 'Kırşehir', ilce: 'Boztepe' },
  { il: 'Kırşehir', ilce: 'Kaman' }, { il: 'Kırşehir', ilce: 'Kırşehir Merkez' }, { il: 'Kırşehir', ilce: 'Mucur' }, { il: 'Kırşehir', ilce: 'Çiçekdağı' },
  { il: 'Malatya', ilce: 'Akçadağ' }, { il: 'Malatya', ilce: 'Arapgir' }, { il: 'Malatya', ilce: 'Arguvan' },
  { il: 'Malatya', ilce: 'Battalgazi' }, { il: 'Malatya', ilce: 'Darende' }, { il: 'Malatya', ilce: 'Doğanyol' },
  { il: 'Malatya', ilce: 'Doğanşehir' }, { il: 'Malatya', ilce: 'Hekimhan' }, { il: 'Malatya', ilce: 'Kale' },
  { il: 'Malatya', ilce: 'Kuluncak' }, { il: 'Malatya', ilce: 'Pütürge' }, { il: 'Malatya', ilce: 'Yazıhan' }, { il: 'Malatya', ilce: 'Yeşilyurt' },
  { il: 'Manisa', ilce: 'Ahmetli' }, { il: 'Manisa', ilce: 'Akhisar' }, { il: 'Manisa', ilce: 'Alaşehir' },
  { il: 'Manisa', ilce: 'Demirci' }, { il: 'Manisa', ilce: 'Gölmarmara' }, { il: 'Manisa', ilce: 'Gördes' },
  { il: 'Manisa', ilce: 'Kula' }, { il: 'Manisa', ilce: 'Köprübaşı' }, { il: 'Manisa', ilce: 'Kırkağaç' },
  { il: 'Manisa', ilce: 'Salihli' }, { il: 'Manisa', ilce: 'Saruhanlı' }, { il: 'Manisa', ilce: 'Sarıgöl' },
  { il: 'Manisa', ilce: 'Selendi' }, { il: 'Manisa', ilce: 'Soma' }, { il: 'Manisa', ilce: 'Turgutlu' },
  { il: 'Manisa', ilce: 'Yunusemre' }, { il: 'Manisa', ilce: 'Şehzadeler' },
  { il: 'Mardin', ilce: 'Artuklu' }, { il: 'Mardin', ilce: 'Dargeçit' }, { il: 'Mardin', ilce: 'Derik' },
  { il: 'Mardin', ilce: 'Kızıltepe' }, { il: 'Mardin', ilce: 'Mazıdağı' }, { il: 'Mardin', ilce: 'Midyat' },
  { il: 'Mardin', ilce: 'Nusaybin' }, { il: 'Mardin', ilce: 'Savur' }, { il: 'Mardin', ilce: 'Yeşilli' }, { il: 'Mardin', ilce: 'Ömerli' },
  { il: 'Mersin', ilce: 'Akdeniz' }, { il: 'Mersin', ilce: 'Anamur' }, { il: 'Mersin', ilce: 'Aydıncık' },
  { il: 'Mersin', ilce: 'Bozyazı' }, { il: 'Mersin', ilce: 'Erdemli' }, { il: 'Mersin', ilce: 'Gülnar' },
  { il: 'Mersin', ilce: 'Mezitli' }, { il: 'Mersin', ilce: 'Mut' }, { il: 'Mersin', ilce: 'Silifke' },
  { il: 'Mersin', ilce: 'Tarsus' }, { il: 'Mersin', ilce: 'Toroslar' }, { il: 'Mersin', ilce: 'Yenişehir' }, { il: 'Mersin', ilce: 'Çamlıyayla' },
  { il: 'Muğla', ilce: 'Bodrum' }, { il: 'Muğla', ilce: 'Dalaman' }, { il: 'Muğla', ilce: 'Datça' },
  { il: 'Muğla', ilce: 'Fethiye' }, { il: 'Muğla', ilce: 'Kavaklıdere' }, { il: 'Muğla', ilce: 'Köyceğiz' },
  { il: 'Muğla', ilce: 'Marmaris' }, { il: 'Muğla', ilce: 'Menteşe' }, { il: 'Muğla', ilce: 'Milas' },
  { il: 'Muğla', ilce: 'Ortaca' }, { il: 'Muğla', ilce: 'Seydikemer' }, { il: 'Muğla', ilce: 'Ula' }, { il: 'Muğla', ilce: 'Yatağan' },
  { il: 'Muş', ilce: 'Bulanık' }, { il: 'Muş', ilce: 'Hasköy' }, { il: 'Muş', ilce: 'Korkut' },
  { il: 'Muş', ilce: 'Malazgirt' }, { il: 'Muş', ilce: 'Muş Merkez' }, { il: 'Muş', ilce: 'Varto' },
  { il: 'Nevşehir', ilce: 'Acıgöl' }, { il: 'Nevşehir', ilce: 'Avanos' }, { il: 'Nevşehir', ilce: 'Derinkuyu' },
  { il: 'Nevşehir', ilce: 'Gülşehir' }, { il: 'Nevşehir', ilce: 'Hacıbektaş' }, { il: 'Nevşehir', ilce: 'Kozaklı' },
  { il: 'Nevşehir', ilce: 'Nevşehir Merkez' }, { il: 'Nevşehir', ilce: 'Ürgüp' },
  { il: 'Niğde', ilce: 'Altunhisar' }, { il: 'Niğde', ilce: 'Bor' }, { il: 'Niğde', ilce: 'Niğde Merkez' },
  { il: 'Niğde', ilce: 'Ulukışla' }, { il: 'Niğde', ilce: 'Çamardı' }, { il: 'Niğde', ilce: 'Çiftlik' },
  { il: 'Ordu', ilce: 'Akkuş' }, { il: 'Ordu', ilce: 'Altınordu' }, { il: 'Ordu', ilce: 'Aybastı' },
  { il: 'Ordu', ilce: 'Fatsa' }, { il: 'Ordu', ilce: 'Gölköy' }, { il: 'Ordu', ilce: 'Gülyalı' },
  { il: 'Ordu', ilce: 'Gürgentepe' }, { il: 'Ordu', ilce: 'Kabadüz' }, { il: 'Ordu', ilce: 'Kabataş' },
  { il: 'Ordu', ilce: 'Korgan' }, { il: 'Ordu', ilce: 'Kumru' }, { il: 'Ordu', ilce: 'Mesudiye' },
  { il: 'Ordu', ilce: 'Perşembe' }, { il: 'Ordu', ilce: 'Ulubey' }, { il: 'Ordu', ilce: 'Çamaş' },
  { il: 'Ordu', ilce: 'Çatalpınar' }, { il: 'Ordu', ilce: 'Çaybaşı' }, { il: 'Ordu', ilce: 'Ünye' }, { il: 'Ordu', ilce: 'İkizce' },
  { il: 'Osmaniye', ilce: 'Bahçe' }, { il: 'Osmaniye', ilce: 'Düziçi' }, { il: 'Osmaniye', ilce: 'Hasanbeyli' },
  { il: 'Osmaniye', ilce: 'Kadirli' }, { il: 'Osmaniye', ilce: 'Osmaniye Merkez' }, { il: 'Osmaniye', ilce: 'Sumbas' }, { il: 'Osmaniye', ilce: 'Toprakkale' },
  { il: 'Rize', ilce: 'Ardeşen' }, { il: 'Rize', ilce: 'Derepazarı' }, { il: 'Rize', ilce: 'Fındıklı' },
  { il: 'Rize', ilce: 'Güneysu' }, { il: 'Rize', ilce: 'Hemşin' }, { il: 'Rize', ilce: 'Kalkandere' },
  { il: 'Rize', ilce: 'Pazar' }, { il: 'Rize', ilce: 'Rize Merkez' }, { il: 'Rize', ilce: 'Çamlıhemşin' },
  { il: 'Rize', ilce: 'Çayeli' }, { il: 'Rize', ilce: 'İkizdere' }, { il: 'Rize', ilce: 'İyidere' },
  { il: 'Sakarya', ilce: 'Adapazarı' }, { il: 'Sakarya', ilce: 'Akyazı' }, { il: 'Sakarya', ilce: 'Arifiye' },
  { il: 'Sakarya', ilce: 'Erenler' }, { il: 'Sakarya', ilce: 'Ferizli' }, { il: 'Sakarya', ilce: 'Geyve' },
  { il: 'Sakarya', ilce: 'Hendek' }, { il: 'Sakarya', ilce: 'Karapürçek' }, { il: 'Sakarya', ilce: 'Karasu' },
  { il: 'Sakarya', ilce: 'Kaynarca' }, { il: 'Sakarya', ilce: 'Kocaali' }, { il: 'Sakarya', ilce: 'Pamukova' },
  { il: 'Sakarya', ilce: 'Sapanca' }, { il: 'Sakarya', ilce: 'Serdivan' }, { il: 'Sakarya', ilce: 'Söğütlü' }, { il: 'Sakarya', ilce: 'Taraklı' },
  { il: 'Samsun', ilce: 'Alaçam' }, { il: 'Samsun', ilce: 'Asarcık' }, { il: 'Samsun', ilce: 'Atakum' },
  { il: 'Samsun', ilce: 'Ayvacık' }, { il: 'Samsun', ilce: 'Bafra' }, { il: 'Samsun', ilce: 'Canik' },
  { il: 'Samsun', ilce: 'Havza' }, { il: 'Samsun', ilce: 'Kavak' }, { il: 'Samsun', ilce: 'Ladik' },
  { il: 'Samsun', ilce: 'Ondokuzmayıs' }, { il: 'Samsun', ilce: 'Salıpazarı' }, { il: 'Samsun', ilce: 'Tekkeköy' },
  { il: 'Samsun', ilce: 'Terme' }, { il: 'Samsun', ilce: 'Vezirköprü' }, { il: 'Samsun', ilce: 'Yakakent' },
  { il: 'Samsun', ilce: 'Çarşamba' }, { il: 'Samsun', ilce: 'İlkadım' },
  { il: 'Siirt', ilce: 'Baykan' }, { il: 'Siirt', ilce: 'Eruh' }, { il: 'Siirt', ilce: 'Kurtalan' },
  { il: 'Siirt', ilce: 'Pervari' }, { il: 'Siirt', ilce: 'Siirt Merkez' }, { il: 'Siirt', ilce: 'Tillo' }, { il: 'Siirt', ilce: 'Şirvan' },
  { il: 'Sinop', ilce: 'Ayancık' }, { il: 'Sinop', ilce: 'Boyabat' }, { il: 'Sinop', ilce: 'Dikmen' },
  { il: 'Sinop', ilce: 'Durağan' }, { il: 'Sinop', ilce: 'Erfelek' }, { il: 'Sinop', ilce: 'Gerze' },
  { il: 'Sinop', ilce: 'Saraydüzü' }, { il: 'Sinop', ilce: 'Sinop Merkez' }, { il: 'Sinop', ilce: 'Türkeli' },
  { il: 'Sivas', ilce: 'Akıncılar' }, { il: 'Sivas', ilce: 'Altınyayla' }, { il: 'Sivas', ilce: 'Divriği' },
  { il: 'Sivas', ilce: 'Doğanşar' }, { il: 'Sivas', ilce: 'Gemerek' }, { il: 'Sivas', ilce: 'Gölova' },
  { il: 'Sivas', ilce: 'Gürün' }, { il: 'Sivas', ilce: 'Hafik' }, { il: 'Sivas', ilce: 'Kangal' },
  { il: 'Sivas', ilce: 'Koyulhisar' }, { il: 'Sivas', ilce: 'Sivas Merkez' }, { il: 'Sivas', ilce: 'Suşehri' },
  { il: 'Sivas', ilce: 'Ulaş' }, { il: 'Sivas', ilce: 'Yıldızeli' }, { il: 'Sivas', ilce: 'Zara' },
  { il: 'Sivas', ilce: 'İmranlı' }, { il: 'Sivas', ilce: 'Şarkışla' },
  { il: 'Tekirdağ', ilce: 'Ergene' }, { il: 'Tekirdağ', ilce: 'Hayrabolu' }, { il: 'Tekirdağ', ilce: 'Kapaklı' },
  { il: 'Tekirdağ', ilce: 'Malkara' }, { il: 'Tekirdağ', ilce: 'Marmaraereğlisi' }, { il: 'Tekirdağ', ilce: 'Muratlı' },
  { il: 'Tekirdağ', ilce: 'Saray' }, { il: 'Tekirdağ', ilce: 'Süleymanpaşa' }, { il: 'Tekirdağ', ilce: 'Çerkezköy' },
  { il: 'Tekirdağ', ilce: 'Çorlu' }, { il: 'Tekirdağ', ilce: 'Şarköy' },
  { il: 'Tokat', ilce: 'Almus' }, { il: 'Tokat', ilce: 'Artova' }, { il: 'Tokat', ilce: 'Başçiftlik' },
  { il: 'Tokat', ilce: 'Erbaa' }, { il: 'Tokat', ilce: 'Niksar' }, { il: 'Tokat', ilce: 'Pazar' },
  { il: 'Tokat', ilce: 'Reşadiye' }, { il: 'Tokat', ilce: 'Sulusaray' }, { il: 'Tokat', ilce: 'Tokat Merkez' },
  { il: 'Tokat', ilce: 'Turhal' }, { il: 'Tokat', ilce: 'Yeşilyurt' }, { il: 'Tokat', ilce: 'Zile' },
  { il: 'Trabzon', ilce: 'Akçaabat' }, { il: 'Trabzon', ilce: 'Araklı' }, { il: 'Trabzon', ilce: 'Arsin' },
  { il: 'Trabzon', ilce: 'Beşikdüzü' }, { il: 'Trabzon', ilce: 'Dernekpazarı' }, { il: 'Trabzon', ilce: 'Düzköy' },
  { il: 'Trabzon', ilce: 'Hayrat' }, { il: 'Trabzon', ilce: 'Köprübaşı' }, { il: 'Trabzon', ilce: 'Maçka' },
  { il: 'Trabzon', ilce: 'Of' }, { il: 'Trabzon', ilce: 'Ortahisar' }, { il: 'Trabzon', ilce: 'Sürmene' },
  { il: 'Trabzon', ilce: 'Tonya' }, { il: 'Trabzon', ilce: 'Vakfıkebir' }, { il: 'Trabzon', ilce: 'Yomra' },
  { il: 'Trabzon', ilce: 'Çarşıbaşı' }, { il: 'Trabzon', ilce: 'Çaykara' }, { il: 'Trabzon', ilce: 'Şalpazarı' },
  { il: 'Tunceli', ilce: 'Hozat' }, { il: 'Tunceli', ilce: 'Mazgirt' }, { il: 'Tunceli', ilce: 'Nazımiye' },
  { il: 'Tunceli', ilce: 'Ovacık' }, { il: 'Tunceli', ilce: 'Pertek' }, { il: 'Tunceli', ilce: 'Pülümür' },
  { il: 'Tunceli', ilce: 'Tunceli Merkez' }, { il: 'Tunceli', ilce: 'Çemişgezek' },
  { il: 'Uşak', ilce: 'Banaz' }, { il: 'Uşak', ilce: 'Eşme' }, { il: 'Uşak', ilce: 'Karahallı' },
  { il: 'Uşak', ilce: 'Sivaslı' }, { il: 'Uşak', ilce: 'Ulubey' }, { il: 'Uşak', ilce: 'Uşak Merkez' },
  { il: 'Van', ilce: 'Bahçesaray' }, { il: 'Van', ilce: 'Başkale' }, { il: 'Van', ilce: 'Edremit' },
  { il: 'Van', ilce: 'Erciş' }, { il: 'Van', ilce: 'Gevaş' }, { il: 'Van', ilce: 'Gürpınar' },
  { il: 'Van', ilce: 'Muradiye' }, { il: 'Van', ilce: 'Saray' }, { il: 'Van', ilce: 'Tuşba' },
  { il: 'Van', ilce: 'Çaldıran' }, { il: 'Van', ilce: 'Çatak' }, { il: 'Van', ilce: 'Özalp' }, { il: 'Van', ilce: 'İpekyolu' },
  { il: 'Yalova', ilce: 'Altınova' }, { il: 'Yalova', ilce: 'Armutlu' }, { il: 'Yalova', ilce: 'Termal' },
  { il: 'Yalova', ilce: 'Yalova Merkez' }, { il: 'Yalova', ilce: 'Çiftlikköy' }, { il: 'Yalova', ilce: 'Çınarcık' },
  { il: 'Yozgat', ilce: 'Akdağmadeni' }, { il: 'Yozgat', ilce: 'Aydıncık' }, { il: 'Yozgat', ilce: 'Boğazlıyan' },
  { il: 'Yozgat', ilce: 'Kadışehri' }, { il: 'Yozgat', ilce: 'Saraykent' }, { il: 'Yozgat', ilce: 'Sarıkaya' },
  { il: 'Yozgat', ilce: 'Sorgun' }, { il: 'Yozgat', ilce: 'Yenifakılı' }, { il: 'Yozgat', ilce: 'Yerköy' },
  { il: 'Yozgat', ilce: 'Yozgat Merkez' }, { il: 'Yozgat', ilce: 'Çandır' }, { il: 'Yozgat', ilce: 'Çayıralan' },
  { il: 'Yozgat', ilce: 'Çekerek' }, { il: 'Yozgat', ilce: 'Şefaatli' },
  { il: 'Zonguldak', ilce: 'Alaplı' }, { il: 'Zonguldak', ilce: 'Devrek' }, { il: 'Zonguldak', ilce: 'Ereğli' },
  { il: 'Zonguldak', ilce: 'Gökçebey' }, { il: 'Zonguldak', ilce: 'Kilimli' }, { il: 'Zonguldak', ilce: 'Kozlu' }, { il: 'Zonguldak', ilce: 'Zonguldak Merkez' }, { il: 'Zonguldak', ilce: 'Çaycuma' },
  { il: 'Çanakkale', ilce: 'Ayvacık' }, { il: 'Çanakkale', ilce: 'Bayramiç' }, { il: 'Çanakkale', ilce: 'Biga' },
  { il: 'Çanakkale', ilce: 'Bozcaada' }, { il: 'Çanakkale', ilce: 'Eceabat' }, { il: 'Çanakkale', ilce: 'Ezine' },
  { il: 'Çanakkale', ilce: 'Gelibolu' }, { il: 'Çanakkale', ilce: 'Gökçeada' }, { il: 'Çanakkale', ilce: 'Lapseki' },
  { il: 'Çanakkale', ilce: 'Yenice' }, { il: 'Çanakkale', ilce: 'Çan' }, { il: 'Çanakkale', ilce: 'Çanakkale Merkez' },
  { il: 'Çankırı', ilce: 'Atkaracalar' }, { il: 'Çankırı', ilce: 'Bayramören' }, { il: 'Çankırı', ilce: 'Eldivan' },
  { il: 'Çankırı', ilce: 'Ilgaz' }, { il: 'Çankırı', ilce: 'Korgun' }, { il: 'Çankırı', ilce: 'Kurşunlu' },
  { il: 'Çankırı', ilce: 'Kızılırmak' }, { il: 'Çankırı', ilce: 'Orta' }, { il: 'Çankırı', ilce: 'Yapraklı' },
  { il: 'Çankırı', ilce: 'Çankırı Merkez' }, { il: 'Çankırı', ilce: 'Çerkeş' }, { il: 'Çankırı', ilce: 'Şabanözü' },
  { il: 'Çorum', ilce: 'Alaca' }, { il: 'Çorum', ilce: 'Bayat' }, { il: 'Çorum', ilce: 'Boğazkale' },
  { il: 'Çorum', ilce: 'Dodurga' }, { il: 'Çorum', ilce: 'Kargı' }, { il: 'Çorum', ilce: 'Laçin' },
  { il: 'Çorum', ilce: 'Mecitözü' }, { il: 'Çorum', ilce: 'Ortaköy' }, { il: 'Çorum', ilce: 'Osmancık' },
  { il: 'Çorum', ilce: 'Oğuzlar' }, { il: 'Çorum', ilce: 'Sungurlu' }, { il: 'Çorum', ilce: 'Uğurludağ' },
  { il: 'Çorum', ilce: 'Çorum Merkez' }, { il: 'Çorum', ilce: 'İskilip' },
  { il: 'İstanbul', ilce: 'Adalar' }, { il: 'İstanbul', ilce: 'Arnavutköy' }, { il: 'İstanbul', ilce: 'Ataşehir' },
  { il: 'İstanbul', ilce: 'Avcılar' }, { il: 'İstanbul', ilce: 'Bahçelievler' }, { il: 'İstanbul', ilce: 'Bakırköy' },
  { il: 'İstanbul', ilce: 'Bayrampaşa' }, { il: 'İstanbul', ilce: 'Bağcılar' }, { il: 'İstanbul', ilce: 'Başakşehir' },
  { il: 'İstanbul', ilce: 'Beykoz' }, { il: 'İstanbul', ilce: 'Beylikdüzü' }, { il: 'İstanbul', ilce: 'Beyoğlu' },
  { il: 'İstanbul', ilce: 'Beşiktaş' }, { il: 'İstanbul', ilce: 'Büyükçekmece' }, { il: 'İstanbul', ilce: 'Esenler' },
  { il: 'İstanbul', ilce: 'Esenyurt' }, { il: 'İstanbul', ilce: 'Eyüpsultan' }, { il: 'İstanbul', ilce: 'Fatih' },
  { il: 'İstanbul', ilce: 'Gaziosmanpaşa' }, { il: 'İstanbul', ilce: 'Güngören' }, { il: 'İstanbul', ilce: 'Kadıköy' },
  { il: 'İstanbul', ilce: 'Kartal' }, { il: 'İstanbul', ilce: 'Kâğıthane' }, { il: 'İstanbul', ilce: 'Küçükçekmece' },
  { il: 'İstanbul', ilce: 'Maltepe' }, { il: 'İstanbul', ilce: 'Pendik' }, { il: 'İstanbul', ilce: 'Sancaktepe' },
  { il: 'İstanbul', ilce: 'Sarıyer' }, { il: 'İstanbul', ilce: 'Silivri' }, { il: 'İstanbul', ilce: 'Sultanbeyli' },
  { il: 'İstanbul', ilce: 'Sultangazi' }, { il: 'İstanbul', ilce: 'Tuzla' }, { il: 'İstanbul', ilce: 'Zeytinburnu' },
  { il: 'İstanbul', ilce: 'Çatalca' }, { il: 'İstanbul', ilce: 'Çekmeköy' }, { il: 'İstanbul', ilce: 'Ümraniye' },
  { il: 'İstanbul', ilce: 'Üsküdar' }, { il: 'İstanbul', ilce: 'Şile' }, { il: 'İstanbul', ilce: 'Şişli' },
  { il: 'İzmir', ilce: 'Aliağa' }, { il: 'İzmir', ilce: 'Balçova' }, { il: 'İzmir', ilce: 'Bayraklı' },
  { il: 'İzmir', ilce: 'Bayındır' }, { il: 'İzmir', ilce: 'Bergama' }, { il: 'İzmir', ilce: 'Beydağ' },
  { il: 'İzmir', ilce: 'Bornova' }, { il: 'İzmir', ilce: 'Buca' }, { il: 'İzmir', ilce: 'Dikili' },
  { il: 'İzmir', ilce: 'Foça' }, { il: 'İzmir', ilce: 'Gaziemir' }, { il: 'İzmir', ilce: 'Güzelbahçe' },
  { il: 'İzmir', ilce: 'Karabağlar' }, { il: 'İzmir', ilce: 'Karaburun' }, { il: 'İzmir', ilce: 'Karşıyaka' },
  { il: 'İzmir', ilce: 'Kemalpaşa' }, { il: 'İzmir', ilce: 'Kiraz' }, { il: 'İzmir', ilce: 'Konak' },
  { il: 'İzmir', ilce: 'Kınık' }, { il: 'İzmir', ilce: 'Menderes' }, { il: 'İzmir', ilce: 'Menemen' },
  { il: 'İzmir', ilce: 'Narlıdere' }, { il: 'İzmir', ilce: 'Seferihisar' }, { il: 'İzmir', ilce: 'Selçuk' },
  { il: 'İzmir', ilce: 'Tire' }, { il: 'İzmir', ilce: 'Torbalı' }, { il: 'İzmir', ilce: 'Urla' },
  { il: 'İzmir', ilce: 'Çeşme' }, { il: 'İzmir', ilce: 'Çiğli' }, { il: 'İzmir', ilce: 'Ödemiş' },
  { il: 'Şanlıurfa', ilce: 'Akçakale' }, { il: 'Şanlıurfa', ilce: 'Birecik' }, { il: 'Şanlıurfa', ilce: 'Bozova' },
  { il: 'Şanlıurfa', ilce: 'Ceylanpınar' }, { il: 'Şanlıurfa', ilce: 'Eyyübiye' }, { il: 'Şanlıurfa', ilce: 'Halfeti' },
  { il: 'Şanlıurfa', ilce: 'Haliliye' }, { il: 'Şanlıurfa', ilce: 'Harran' }, { il: 'Şanlıurfa', ilce: 'Hilvan' },
  { il: 'Şanlıurfa', ilce: 'Karaköprü' }, { il: 'Şanlıurfa', ilce: 'Siverek' }, { il: 'Şanlıurfa', ilce: 'Suruç' },
  { il: 'Şanlıurfa', ilce: 'Viranşehir' },
  { il: 'Şırnak', ilce: 'Beytüşşebap' }, { il: 'Şırnak', ilce: 'Cizre' }, { il: 'Şırnak', ilce: 'Güçlükonak' },
  { il: 'Şırnak', ilce: 'Silopi' }, { il: 'Şırnak', ilce: 'Uludere' }, { il: 'Şırnak', ilce: 'İdil' }, { il: 'Şırnak', ilce: 'Şırnak Merkez' }
];

  constructor(private readonly httpService: HttpService) {
    super();
  }

  async onModuleInit() {
    await this.$connect();
    this.logger.log('✅ [Usta Service] Veritabanı bağlantısı başarılı.');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  // --- CRUD İŞLEMLERİ ---
  async create(data: any) { return await this.provider.create({ data }); }
  async findAll() { return await this.provider.findMany({ include: { user: true } }); }
  async findOne(id: string) { return await this.provider.findUnique({ where: { id }, include: { user: true } }); }
  async update(id: string, data: any) { return await this.provider.update({ where: { id }, data }); }
  async delete(id: string) {
    try { await this.provider.delete({ where: { id } }); return { success: true }; }
    catch (e) { return { success: false }; }
  }

  // --- KATEGORİ VE FİLTRELEME ---
  async getCities() {
    const uniqueCities = await this.provider.findMany({ distinct: ['city'], select: { city: true } });
    return uniqueCities.map((item, index) => ({ id: String(index + 1), name: item.city }));
  }

  async getDistricts(city: string) {
    const districts = await this.provider.findMany({ where: { city }, distinct: ['district'], select: { district: true } });
    return districts.map((item, index) => ({ id: String(index + 1), name: item.district }));
  }

  async getCategories() {
    return [
      { id: 'TECHNICAL', name: 'Teknik Servis' },
      { id: 'CONSTRUCTION', name: 'Yapı & Dekorasyon' },
      { id: 'CLIMATE', name: 'İklimlendirme' },
      { id: 'TECH', name: 'Cihaz & Teknoloji' },
      { id: 'LIFE', name: 'Yaşam & Bakım' }
    ];
  }

  // --- 🔥 CRAWLER MOTORU ---
  async startTurkeyGeneralCrawl() {
    this.logger.log('🚀 USTA TARAMASI BAŞLATILDI...');
    const keywords = [
      'elektrikçi', 'su tesisatçısı', 'boyacı',
      'laminantçı', 'camcı', 'marangoz', 'anahtarcı',
      'klima servisi', 'kombi tamiri',
      'beyaz eşya tamiri', 'televizyon tamiri', 'bilgisayar tamiri',
      'temizlik şirketi', 'ilaçlama firması'
    ];

    let stats = { totalFound: 0, newlySaved: 0, skipped: 0 };

    for (const region of this.TURKEY_DATA) {
      for (const keyword of keywords) {
        const query = `${keyword} ${region.ilce} ${region.il}`;
        try {
          const results = await this.searchGooglePlaces(query);
          for (const place of results) {
            stats.totalFound++;
            const details = await this.getPlaceDetails(place.place_id);
            if (!details?.formatted_phone_number) {
              stats.skipped++;
              continue;
            }
            const saved = await this.saveToPrisma(details, region.il, region.ilce, keyword);
            if (saved) stats.newlySaved++;
            else stats.skipped++;

            await new Promise(res => setTimeout(res, 1500));
          }
        } catch (err: any) {
          this.logger.error(`❌ Hata (${query}): ${err.message}`);
        }
      }
    }
    return stats;
  }

  private async searchGooglePlaces(query: string) {
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(query)}&key=${this.apiKey}&language=tr`;
    const { data }: any = await firstValueFrom(this.httpService.get(url));
    return data.results || [];
  }

  private async getPlaceDetails(placeId: string) {
    const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,formatted_phone_number,formatted_address,geometry,website,types&key=${this.apiKey}&language=tr`;
    const { data }: any = await firstValueFrom(this.httpService.get(url));
    return data.result;
  }

  private mapKeywordToType(keyword: string) {
    const k = keyword.toLowerCase();
    if (k.match(/elektrik|tesisat|boya/)) return { main: 'TECHNICAL', sub: k.replace(/\s+/g, '_') };
    if (k.match(/laminant|cam|marangoz|çatı|anahtar/)) return { main: 'CONSTRUCTION', sub: k.replace(/\s+/g, '_') };
    if (k.match(/klima|kombi/)) return { main: 'CLIMATE', sub: k.replace(/\s+/g, '_') };
    if (k.match(/beyaz eşya|televizyon|bilgisayar|telefon/)) return { main: 'TECH', sub: k.replace(/\s+/g, '_') };
    if (k.match(/temizlik|ilaçlama|yemek|bakıcı|hayvan/)) return { main: 'LIFE', sub: k.replace(/\s+/g, '_') };
    return { main: 'TECHNICAL', sub: 'genel' };
  }

  private async saveToPrisma(details: any, city: string, district: string, keyword: string): Promise<boolean> {
    const rawPhone = details.formatted_phone_number.replace(/\D/g, '').slice(-10);
    const exists = await this.provider.findFirst({ where: { phoneNumber: details.formatted_phone_number } });
    if (exists) return false;

    try {
      const passwordHash = await bcrypt.hash('Usta2026!', 10);
      const email = `u_${rawPhone}@ustasistemi.com`;
      const { main, sub } = this.mapKeywordToType(keyword);

      await this.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: { email, password: passwordHash, role: 'PROVIDER', isActive: true }
        });
        await tx.provider.create({
          data: {
            userId: user.id,
            businessName: details.name,
            phoneNumber: details.formatted_phone_number,
            city, district, address: details.formatted_address,
            mainType: main, subType: sub,
            lat: details.geometry.location.lat,
            lng: details.geometry.location.lng,
            website: details.website || '',
            openingFee: 500, pricePerUnit: 100
          }
        });
      });
      return true;
    } catch (e) { return false; }
  }
}
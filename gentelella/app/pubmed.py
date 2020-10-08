import entrezpy.conduit
import json
import xml.etree.ElementTree
import entrezpy.base.result
import entrezpy.base.analyzer
import re


def remove_html_tags(text):
    """Remove html tags from a string"""
    clean = re.compile('<.*?>')
    return re.sub(clean, '', text)

class PubmedRecord:
    """Simple data class to store individual Pubmed records. Individual authors will
  be stored as dict('lname':last_name, 'fname': first_name) in authors.
  Citations as string elements in the list citations. """

    def __init__(self):
        self.pmid = None
        self.title = None
        self.abstract = None
        self.authors = []
        self.references = []
        self.pubmeddate = ""
        self.idlist = ""
        self.med = ""
        self.relevance = ""
        self.notes = ""
        self.user = ""


class PubmedResult(entrezpy.base.result.EutilsResult):
    """Derive class entrezpy.base.result.EutilsResult to store Pubmed queries.
  Individual Pubmed records are implemented in :class:`PubmedRecord` and
  stored in :ivar:`pubmed_records`.

  :param response: inspected response from :class:`PubmedAnalyzer`
  :param request: the request for the current response
  :ivar dict pubmed_records: storing PubmedRecord instances"""

    def __init__(self, response, request):
        super().__init__(request.eutil, request.query_id, request.db)
        self.pubmed_records = {}

    def size(self):
        """Implement virtual method :meth:`entrezpy.base.result.EutilsResult.size`
    returning the number of stored data records."""
        return len(self.pubmed_records)

    def isEmpty(self):
        """Implement virtual method :meth:`entrezpy.base.result.EutilsResult.isEmpty`
    to query if any records have been stored at all."""
        if not self.pubmed_records:
            return True
        return False

    def get_link_parameter(self, reqnum=0):
        """Implement virtual method :meth:`entrezpy.base.result.EutilsResult.get_link_parameter`.
    Fetching a pubmed record has no intrinsic elink capabilities and therefore
    should inform users about this."""
        print("{} has no elink capability".format(self))
        return {}

    def dump(self):
        """Implement virtual method :meth:`entrezpy.base.result.EutilsResult.dump`.

    :return: instance attributes
    :rtype: dict
    """

        return {self: {'dump': {'pubmed_records': [x for x in self.pubmed_records],
                                'query_id': self.query_id, 'db': self.db,
                                'eutil': self.function}}}

    def add_pubmed_record(self, pubmed_record):
        """The only non-virtual and therefore PubmedResult-specific method to handle
    adding new data records"""
        self.pubmed_records[pubmed_record.pmid] = pubmed_record




class PubmedAnalyzer(entrezpy.base.analyzer.EutilsAnalyzer):
    """Derived class of :class:`entrezpy.base.analyzer.EutilsAnalyzer` to analyze and
  parse PubMed responses and requests."""

    def __init__(self):
        super().__init__()

    def init_result(self, response, request):
        """Implemented virtual method :meth:`entrezpy.base.analyzer.init_result`.
    This method initiate a result instance when analyzing the first response"""
        if self.result is None:
            self.result = PubmedResult(response, request)

    def analyze_error(self, response, request):
        """Implement virtual method :meth:`entrezpy.base.analyzer.analyze_error`. Since
    we expect XML errors, just print the error to STDOUT for
    logging/debugging."""
        print(json.dumps({__name__: {'Response': {'dump': request.dump(),
                                                  'error': response.getvalue()}}}))


    def analyze_result(self, response, request):
        """Implement virtual method :meth:`entrezpy.base.analyzer.analyze_result`.
    Parse PubMed  XML line by line to extract authors and citations.
    xml.etree.ElementTree.iterparse
    (https://docs.python.org/3/library/xml.etree.elementtree.html#xml.etree.ElementTree.iterparse)
    reads the XML file incrementally. Each  <PubmedArticle> is cleared after processing.

    ..note::  Adjust this method to include more/different tags to extract.
              Remember to adjust :class:`.PubmedRecord` as well."""
        self.init_result(response, request)
        isAuthorList = False
        isAuthor = False
        isRefList = False
        isRef = False
        isArticle = False
        isDate = False
        isIDLIST = False
        isMed = False
        PubmedData = False
        medrec = None
        for event, elem in xml.etree.ElementTree.iterparse(response, events=["start", "end"]):
            # print(elem)
            if event == 'start':
                if elem.tag == 'PubmedArticle':
                    medrec = PubmedRecord()
                if elem.tag == 'Count':
                    PubmedData = True
                if elem.tag == 'AuthorList':
                    isAuthorList = True
                if isAuthorList and elem.tag == 'Author':
                    isAuthor = True
                    medrec.authors.append({'fname': None, 'lname': None})
                if elem.tag == 'ReferenceList':
                    isRefList = True
                if isRefList and elem.tag == 'Reference':
                    isRef = True
                if elem.tag == 'Article':
                    isArticle = True
                if elem.tag == 'ELocationID':
                    isIDLIST = True
                if elem.tag == 'PublicationType':
                    isMed = True
                if elem.tag in ["Day", "Month", "Year"]:
                    isDate = True

            else:
                if elem.tag == 'PubmedArticle':
                    self.result.add_pubmed_record(medrec)
                    # elem.clear()
                if elem.tag == 'AuthorList':
                    isAuthorList = False
                if isAuthorList and elem.tag == 'Author':
                    isAuthor = False
                if elem.tag == 'ReferenceList':
                    isRefList = False
                if elem.tag == 'Reference':
                    isRef = False
                if elem.tag == 'Article':
                    isArticle = False
                if elem.tag == 'PMID':
                    medrec.pmid = elem.text.strip()
                if isAuthor and elem.tag == 'LastName':
                    medrec.authors[-1]['lname'] = elem.text.strip()
                if isAuthor and elem.tag == 'ForeName':
                    medrec.authors[-1]['fname'] = elem.text.strip()
                if isRef and elem.tag == 'Citation':
                    medrec.references.append(elem.text.strip())
                if PubmedData and elem.tag == 'Count':
                    PubmedData = elem.text.strip()
                    print(PubmedData)
                if isArticle and elem.tag == 'AbstractText':
                    if not medrec.abstract:
                        medrec.abstract = "".join(elem.itertext()).strip()
                    else:
                        medrec.abstract += "".join(elem.itertext()).strip()
                if isArticle and elem.tag == 'ArticleTitle':
                    medrec.title = "".join(elem.itertext()).strip()
                if isIDLIST and elem.tag == 'ELocationID':
                    medrec.idlist= elem.text.strip()
                if isMed and elem.tag == 'PublicationType':
                     medrec.med = elem.text.strip()
                if isDate:
                    if elem.tag == "Year":
                        medrec.pubmeddate = "{}".format(elem.text.strip())
                    elif elem.tag == "Month":
                        medrec.pubmeddate = "{} - {}".format(medrec.pubmeddate,
                                                             elem.text.strip())
                    elif elem.tag == "Day":
                        medrec.pubmeddate = "{} - {}".format(medrec.pubmeddate,
                                                             elem.text.strip())




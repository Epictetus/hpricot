
import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObjectAdapter;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.runtime.Block;
import org.jruby.runtime.CallbackFactory;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.load.BasicLibraryService;

public class HpricotScanService implements BasicLibraryService {
    // hpricot_state
    public static class State {
        public IRubyObject doc;
        public IRubyObject focus;
        public IRubyObject last;
        public IRubyObject EC;
        public boolean xml, strict, fixup;
    }

    static boolean OPT(IRubyObject opts, String key) {
        Ruby runtime = opts.getRuntime();
        return !opts.isNil() && ((RubyHash)opts).op_aref(runtime.getCurrentContext(), runtime.newSymbol(key)).isTrue();
    }

    public static class Scanner {
%%{
  machine hpricot_scan;

  action newEle {
    if (text == 1) {
      CAT(tag, p);
      ELE(text);
      text = 0;
    }
    attr = Qnil;
    tag = Qnil;
    mark_tag = NULL;
    ele_open = 1;
  }

  action _tag { mark_tag = p; }
  action _aval { mark_aval = p; }
  action _akey { mark_akey = p; }
  action tag { SET(tag, p); }
  action tagc { SET(tag, p-1); }
  action aval { SET(aval, p); }
  action aunq {
    if (*(p-1) == '"' || *(p-1) == '\'') { SET(aval, p-1); }
    else { SET(aval, p); }
  }
  action akey { SET(akey, p); }
  action xmlver { SET(aval, p); ATTR(ID2SYM(rb_intern("version")), aval); }
  action xmlenc { SET(aval, p); ATTR(ID2SYM(rb_intern("encoding")), aval); }
  action xmlsd  { SET(aval, p); ATTR(ID2SYM(rb_intern("standalone")), aval); }
  action pubid  { SET(aval, p); ATTR(ID2SYM(rb_intern("public_id")), aval); }
  action sysid  { SET(aval, p); ATTR(ID2SYM(rb_intern("system_id")), aval); }

  action new_attr {
    akey = Qnil;
    aval = Qnil;
    mark_akey = NULL;
    mark_aval = NULL;
  }

  action save_attr {
    if (!S->xml)
      akey = rb_funcall(akey, s_downcase, 0);
    ATTR(akey, aval);
  }

  include hpricot_common "hpricot_common.rl";

}%%

%% write data nofinal;

        public final static int BUFSIZE = 16384;


        private int cs, act, have = 0, nread = 0, curline = 1, text = 0;
        private int ts = 0, te = 0, eof = -1, p = -1;
        private byte[] buf;
        private State S = null;
        private IRubyObject port, opts, attr, tag, akey, aval, bufsize;
        private int mark_tag = 0, mark_akey = 0, mark_aval = 0;
        private boolean done = false, ele_open = false, taint = false, io = false;
        private int buffer_size = 0;

        private Extra x;


        private IRubyObject self;
        private Ruby runtime;
        private ThreadContext ctx;
        private Block block;
        public Scanner(IRubyObject self, IRubyObject[] args, Block block) {
            this.self = self;
            this.runtime = self.getRuntime();
            this.ctx = runtime.getCurrentContext();
            this.block = block;
            attr = runtime.getNil();
            tag = runtime.getNil();
            akey = runtime.getNil();
            aval = runtime.getNil();
            bufsize = runtime.getNil();

            this.x = (Extra)this.runtime.getModule("Hpricot").dataWrapStruct();

            port = args[0];
            if(args.length == 2) {
                opts = args[1];
            } else {
                opts = runtime.getNil();
            }

            taint = port.isTaint();
            io = port.respondsTo("read");
            if(!io) {
                if(port.respondsTo("to_str")) {
                    port = port.callMethod(ctx, "to_str");
                    port = port.convertToString();
                } else {
                    throw runtime.newArgumentError("an Hpricot document must be built from an input source (a String or IO object.)");
                }
            }

            if(!(opts instanceof RubyHash)) {
                opts = runtime.getNil();
            }

            if(!block.isGiven()) {
                S = new State();
                S.doc = x.cDoc.allocate();
                S.focus = S.doc;
                S.last = runtime.getNil();
                S.xml = OPT(opts, "xml");
                S.strict = OPT(opts, "xhtml_strict");
                S.fixup = OPT(opts, "fixup_tags");
                if(S.strict) {
                    S.fixup = true;
                }
                S.doc.getInstanceVariables().fastSetInstanceVariable("@options", opts);
                S.EC = x.mHpricot.getConstant("ElementContent");
            }

            buffer_size = BUFSIZE;
            if(self.getInstanceVariables().fastHasInstanceVariable("@buffer_size")) {
                bufsize = self.getInstanceVariables().fastGetInstanceVariable("@buffer_size");
                if(!bufsize.isNil()) {
                    buffer_size = RubyNumeric.fix2int(bufsize);
                }
            }

            if(io) {
                buf = new byte[bufer_size];
            }
        }
        
        // hpricot_scan
        public IRubyObject scan() {
%% write init;


            

        }






  while (!done) {
    VALUE str;
    char *p, *pe;
    int len, space = buffer_size - have, tokstart_diff, tokend_diff, mark_tag_diff, mark_akey_diff, mark_aval_diff;

    if (io)
    {
      if (space == 0) {
        /* We've used up the entire buffer storing an already-parsed token
         * prefix that must be preserved.  Likely caused by super-long attributes.
         * Increase buffer size and continue  */
         tokstart_diff = ts - buf;
         tokend_diff = te - buf;
         mark_tag_diff = mark_tag - buf;
         mark_akey_diff = mark_akey - buf;
         mark_aval_diff = mark_aval - buf;

         buffer_size += BUFSIZE;
         REALLOC_N(buf, char, buffer_size);

         space = buffer_size - have;

         ts = buf + tokstart_diff;
         te = buf + tokend_diff;
         mark_tag = buf + mark_tag_diff;
         mark_akey = buf + mark_akey_diff;
         mark_aval = buf + mark_aval_diff;
      }
      p = buf + have;

      str = rb_funcall(port, s_read, 1, INT2FIX(space));
      len = RSTRING_LEN(str);
      memcpy(p, StringValuePtr(str), len);
    }
    else
    {
      p = RSTRING_PTR(port);
      len = RSTRING_LEN(port) + 1;
      done = 1;
    }

    nread += len;

    /* If this is the last buffer, tack on an EOF. */
    if (io && len < space) {
      p[len++] = 0;
      done = 1;
    }

    pe = p + len;
    %% write exec;

    if (cs == hpricot_scan_error) {
      if (buf != NULL)
        free(buf);
      if (!NIL_P(tag))
      {
        rb_raise(rb_eHpricotParseError, "parse error on element <%s>, starting on line %d.\n" NO_WAY_SERIOUSLY, RSTRING_PTR(tag), curline);
      }
      else
      {
        rb_raise(rb_eHpricotParseError, "parse error on line %d.\n" NO_WAY_SERIOUSLY, curline);
      }
    }

    if (done && ele_open)
    {
      ele_open = 0;
      if (ts > 0) {
        mark_tag = ts;
        ts = 0;
        text = 1;
      }
    }

    if (ts == 0)
    {
      have = 0;
      /* text nodes have no ts because each byte is parsed alone */
      if (mark_tag != NULL && text == 1)
      {
        if (done)
        {
          if (mark_tag < p-1)
          {
            CAT(tag, p-1);
            ELE(text);
          }
        }
        else
        {
          CAT(tag, p);
        }
      }
      if (io)
        mark_tag = buf;
      else
        mark_tag = RSTRING_PTR(port);
    }
    else if (io)
    {
      have = pe - ts;
      memmove(buf, ts, have);
      SLIDE(tag);
      SLIDE(akey);
      SLIDE(aval);
      te = buf + (te - ts);
      ts = buf;
    }
  }

  if (buf != NULL)
    free(buf);

  if (S != NULL)
  {
    VALUE doc = S->doc;
    rb_gc_unregister_address(&S->doc);
    free(S);
    return doc;
  }

  return Qnil;
}


    public static class HpricotModule {
        // hpricot_scan
        @JRubyMethod(module = true)
        public static IRubyObject scan(IRubyObject self, IRubyObject[] args) {
            // TODO: implement
            return null;
        }

        // hpricot_css
        @JRubyMethod(module = true)
        public static IRubyObject css(IRubyObject self, IRubyObject one, IRubyObject two, IRubyObject three) {
            // TODO: implement
            return null;
        }
    }

    public static class CData {
        @JRubyMethod
        public static IRubyObject content(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod(name = "content=")
        public static IRubyObject content_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_name(self, value);
        }
    }

    public static class Comment {
        @JRubyMethod
        public static IRubyObject content(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod(name = "content=")
        public static IRubyObject content_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_name(self, value);
        }
    }

    public static class DocType {
        @JRubyMethod
        public static IRubyObject raw_string(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod
        public static IRubyObject clear_raw(IRubyObject self) {
            return hpricot_ele_clear_name(self);
        }

        @JRubyMethod
        public static IRubyObject target(IRubyObject self) {
            return hpricot_ele_get_target(self);
        }

        @JRubyMethod(name = "target=")
        public static IRubyObject target_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_target(self, value);
        }

        @JRubyMethod
        public static IRubyObject public_id(IRubyObject self) {
            return hpricot_ele_get_public_id(self);
        }

        @JRubyMethod(name = "public_id=")
        public static IRubyObject public_id_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_public_id(self, value);
        }

        @JRubyMethod
        public static IRubyObject system_id(IRubyObject self) {
            return hpricot_ele_get_system_id(self);
        }

        @JRubyMethod(name = "system_id=")
        public static IRubyObject system_id_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_system_id(self, value);
        }
    }

    public static class Elem {
        @JRubyMethod
        public static IRubyObject clear_raw(IRubyObject self) {
            return hpricot_ele_clear_raw(self);
        }
    }

    public static class BogusETag {
        @JRubyMethod
        public static IRubyObject raw_string(IRubyObject self) {
            return hpricot_ele_get_attr(self);
        }

        @JRubyMethod
        public static IRubyObject clear_raw(IRubyObject self) {
            return hpricot_ele_clear_attr(self);
        }
    }

    public static class Text {
        @JRubyMethod
        public static IRubyObject raw_string(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod
        public static IRubyObject clear_raw(IRubyObject self) {
            return hpricot_ele_clear_name(self);
        }

        @JRubyMethod
        public static IRubyObject content(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod(name = "content=")
        public static IRubyObject content_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_name(self, value);
        }
    }

    public static class XMLDecl {
        @JRubyMethod
        public static IRubyObject raw_string(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod
        public static IRubyObject clear_raw(IRubyObject self) {
            return hpricot_ele_clear_name(self);
        }

        @JRubyMethod
        public static IRubyObject encoding(IRubyObject self) {
            return hpricot_ele_get_encoding(self);
        }

        @JRubyMethod(name = "encoding=")
        public static IRubyObject encoding_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_encoding(self, value);
        }

        @JRubyMethod
        public static IRubyObject standalone(IRubyObject self) {
            return hpricot_ele_get_standalone(self);
        }

        @JRubyMethod(name = "standalone=")
        public static IRubyObject standalone_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_standalone(self, value);
        }

        @JRubyMethod
        public static IRubyObject version(IRubyObject self) {
            return hpricot_ele_get_version(self);
        }

        @JRubyMethod(name = "version=")
        public static IRubyObject version_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_version(self, value);
        }
    }

    public static class ProcIns {
        @JRubyMethod
        public static IRubyObject target(IRubyObject self) {
            return hpricot_ele_get_name(self);
        }

        @JRubyMethod(name = "target=")
        public static IRubyObject target_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_name(self, value);
        }

        @JRubyMethod
        public static IRubyObject content(IRubyObject self) {
            return hpricot_ele_get_attr(self);
        }

        @JRubyMethod(name = "content=")
        public static IRubyObject content_set(IRubyObject self, IRubyObject value) {
            return hpricot_ele_set_attr(self, value);
        }
    }

    public final static String NO_WAY_SERIOUSLY = "*** This should not happen, please send a bug report with the HTML you're parsing to why@whytheluckystiff.net.  So sorry!";

    public final static int H_ELE_TAG = 0;
    public final static int H_ELE_PARENT = 1;
    public final static int H_ELE_ATTR = 2;
    public final static int H_ELE_ETAG = 3;
    public final static int H_ELE_RAW = 4;
    public final static int H_ELE_EC = 5;
    public final static int H_ELE_HASH = 6;
    public final static int H_ELE_CHILDREN = 7;

    public static IRubyObject H_ELE_GET(IRubyObject recv, int n) {
        return ((IRubyObject[])recv.dataGetStruct())[n];
    }

    public static IRubyObject H_ELE_SET(IRubyObject recv, int n, IRubyObject value) {
        ((IRubyObject[])recv.dataGetStruct())[n] = value;
        return value;
    }

    private static class RefCallback implements Callback {
        private final int n;
        public RefCallback(int n) { this.n = n; }

        public IRubyObject execute(IRubyObject recv, IRubyObject[] args, Block block) {
            return H_ELE_GET(recv, n);
        }

        public Arity getArity() {
            return Arity.NO_ARGUMENTS;
        }
    }

    private static class SetCallback implements Callback {
        private final int n;
        public SetCallback(int n) { this.n = n; }

        public IRubyObject execute(IRubyObject recv, IRubyObject[] args, Block block) {
            return H_ELE_SET(recv, n, args[0]);
        }

        public Arity getArity() {
            return Arity.ONE_ARGUMENT;
        }
    }

    private final static Callback[] ref_func = new Callback[]{
        new RefCallback(0),
        new RefCallback(1),
        new RefCallback(2),
        new RefCallback(3),
        new RefCallback(4),
        new RefCallback(5),
        new RefCallback(6),
        new RefCallback(7),
        new RefCallback(8),
        new RefCallback(9)};

    private final static Callback[] set_func = new Callback[]{
        new SetCallback(0),
        new SetCallback(1),
        new SetCallback(2),
        new SetCallback(3),
        new SetCallback(4),
        new SetCallback(5),
        new SetCallback(6),
        new SetCallback(7),
        new SetCallback(8),
        new SetCallback(9)};

    public final static ObjectAllocator alloc_hpricot_struct = new ObjectAllocator() {
            // alloc_hpricot_struct
            public IRubyObject allocate(Ruby runtime, RubyClass klass) {
                int size = RubyNumeric.fix2int(klass.fastGetInternalVariable("__size__"));
                RubyObject obj = new RubyObject(runtime, klass);
                obj.dataWrapStruct(new IRubyObject[size]);
                return obj;
            }
        };

    public static RubyClass makeHpricotStruct(Ruby runtime, IRubyObject[] members) {
        RubyClass klass = RubyClass.newClass(runtime, runtime.getObject());
        klass.fastSetInternalVariable("__size__", runtime.newFixnum(members.length));
        klass.setAllocator(alloc_hpricot_struct);

        for(int i = 0; i < members.length; i++) {
            String id = members[i].toString();
            klass.defineMethod(id, ref_func[i]);
            klass.defineMethod(id + "=", set_func[i]);
        }
    
        return klass;
    }

    public boolean basicLoad(final Ruby runtime) throws IOException {
        Init_hpricot_scan(runtime);
        return true;
    }

    public static class Extra {
        IRubyObject symAllow, symDeny, sym_xmldecl, sym_doctype, 
            sym_procins, sym_stag, sym_etag, sym_emptytag, 
            sym_allowed, sym_children, sym_comment, 
            sym_cdata, sym_name, sym_parent, 
            sym_raw_attributes, sym_raw_string, sym_tagno, 
            sym_text, sym_EMPTY, sym_CDATA;

        public RubyModule mHpricot;
        public RubyClass structElem;
        public RubyClass structAttr;
        public RubyClass structBasic;
        public RubyClass cDoc;
        public RubyClass cCData;
        public RubyClass cComment;
        public RubyClass cDocType;
        public RubyClass cElem;
        public RubyClass cBogusETag;
        public RubyClass cText;
        public RubyClass cXMLDecl;
        public RubyClass cProcIns;
        public IRubyObject reProcInsParse;

        public Extra(Ruby runtime) {
            symAllow = runtime.newSymbol("allow");
            symDeny = runtime.newSymbol("deny");
            sym_xmldecl = runtime.newSymbol("xmldecl");
            sym_doctype = runtime.newSymbol("doctype");
            sym_procins = runtime.newSymbol("procins");
            sym_stag = runtime.newSymbol("stag");
            sym_etag = runtime.newSymbol("etag");
            sym_emptytag = runtime.newSymbol("emptytag");
            sym_allowed = runtime.newSymbol("allowed");
            sym_children = runtime.newSymbol("children");
            sym_comment = runtime.newSymbol("comment");
            sym_cdata = runtime.newSymbol("cdata");
            sym_name = runtime.newSymbol("name");
            sym_parent = runtime.newSymbol("parent");
            sym_raw_attributes = runtime.newSymbol("raw_attributes");
            sym_raw_string = runtime.newSymbol("raw_string");
            sym_tagno = runtime.newSymbol("tagno");
            sym_text = runtime.newSymbol("text");
            sym_EMPTY = runtime.newSymbol("EMPTY");
            sym_CDATA = runtime.newSymbol("CDATA");
        }
    }

    public static void Init_hpricot_scan(Ruby runtime) {
        Extra x = new Extra(runtime);

        x.mHpricot = runtime.defineModule("Hpricot");
        x.mHpricot.dataSetStruct(x);

        x.mHpricot.getSingletonClass().attr_accessor(runtime.getCurrentContext(),new  IRubyObject[]{runtime.newSymbol("buffer_size")});
        x.mHpricot.defineAnnotatedMethods(HpricotModule.class);

        x.mHpricot.defineClassUnder("ParseError",runtime.getClass("StandardError"),runtime.getClass("StandardError").getAllocator());

        x.structElem = makeHpricotStruct(runtime, new IRubyObject[] {x.sym_name, x.sym_parent, x.sym_raw_attributes, x.sym_etag, x.sym_raw_string, x.sym_allowed, x.sym_tagno, x.sym_children});
        x.structAttr = makeHpricotStruct(runtime, new IRubyObject[] {x.sym_name, x.sym_parent, x.sym_raw_attributes});
        x.structBasic= makeHpricotStruct(runtime, new IRubyObject[] {x.sym_name, x.sym_parent});

        x.cDoc = x.mHpricot.defineClassUnder("Doc", x.structElem, x.structElem.getAllocator());

        x.cCData = x.mHpricot.defineClassUnder("CData", x.structBasic, x.structBasic.getAllocator());
        x.cCData.defineAnnotatedMethods(CData.class);

        x.cComment = x.mHpricot.defineClassUnder("Comment", x.structBasic, x.structBasic.getAllocator());
        x.cComment.defineAnnotatedMethods(Comment.class);

        x.cDocType = x.mHpricot.defineClassUnder("DocType", x.structAttr, x.structAttr.getAllocator());
        x.cDocType.defineAnnotatedMethods(DocType.class);

        x.cElem = mHpricot.defineClassUnder("Elem", x.structElem, x.structElem.getAllocator());
        x.cElem.defineAnnotatedMethods(Elem.class);

        x.cBogusETag = x.mHpricot.defineClassUnder("BogusETag", x.structAttr, x.structAttr.getAllocator());
        x.cBogusETag.defineAnnotatedMethods(BogusETag.class);

        x.cText = x.mHpricot.defineClassUnder("Text", x.structBasic, x.structBasic.getAllocator());
        x.cText.defineAnnotatedMethods(Text.class);

        x.cXMLDecl = x.mHpricot.defineClassUnder("XMLDecl", x.structAttr, x.structAttr.getAllocator());
        x.cXMLDecl.defineAnnotatedMethods(XMLDecl.class);

        x.cProcIns = x.mHpricot.defineClassUnder("ProcIns", x.structAttr, x.structAttr.getAllocator());
        x.cProcIns.defineAnnotatedMethods(ProcIns.class);

        x.reProcInsParse = runtime.evalScriptlet("/\\A<\\?(\\S+)\\s+(.+)/m");
        x.mHpricot.setConstant("ProcInsParse", x.reProcInsParse);
    }
}
